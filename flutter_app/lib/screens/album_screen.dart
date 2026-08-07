import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/music_api.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/download_button.dart';
import '../providers/player_provider.dart';
import '../api/image_proxy.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  final String browseId;
  final String title;

  const AlbumScreen({super.key, required this.browseId, required this.title});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  late Future<AlbumDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = MusicApi().getAlbum(widget.browseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AlbumDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('Error cargando álbum', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(snap.error.toString(), textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() => _future = MusicApi().getAlbum(widget.browseId)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final album = snap.data!;
          return _buildContent(context, album);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AlbumDetail album) {
    return CustomScrollView(
      slivers: [
        // AppBar con portada
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: AppTheme.bgDeep,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              album.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (album.thumbnail != null)
                  CachedNetworkImage(
                    imageUrl: proxyImageUrl(album.thumbnail!)!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(color: AppTheme.bgSurface),
                // Degradado encima de la imagen
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppTheme.bgDeep],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Info del álbum
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(album.artist, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accent,
                )),
                if (album.year != null || album.trackCount != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (album.year != null)
                        Text('${album.year}', style: Theme.of(context).textTheme.bodyMedium),
                      if (album.year != null && album.trackCount != null)
                        const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                      if (album.trackCount != null)
                        Text('${album.trackCount} canciones', style: Theme.of(context).textTheme.bodyMedium),
                      if (album.duration != null) ...[
                        const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                        Text(album.duration!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(color: AppTheme.divider),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ),

        // Tracklist
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final track = album.tracks[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.bgCard,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  onTap: () {
                    ref.read(playerProvider.notifier).playFromQueue(
                      album.tracks,
                      i,
                    );
                  },
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.bgSurface,
                    ),
                    child: Center(
                      child: Text(
                        '${track.trackNumber ?? i + 1}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: track.duration != null
                      ? Text(
                          track.duration!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        )
                      : null,
                  trailing: DownloadButton(
                    videoId: track.videoId,
                    title: track.title,
                    artist: track.artist,
                    size: 34,
                  ),
                ),
              ).animate().fadeIn(delay: (i * 30).ms).slideX(begin: 0.05, end: 0);
            },
            childCount: album.tracks.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }
}
