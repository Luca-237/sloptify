import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../api/image_proxy.dart';
import 'full_screen_player.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  void _showFullScreenPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FullScreenPlayer(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    final notifier = ref.read(playerProvider.notifier);

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showFullScreenPlayer(context),
      child: Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            children: [
              // Portada de la canción
              if (song.thumbnail != null)
                CachedNetworkImage(
                  imageUrl: proxyImageUrl(song.thumbnail!)!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              const SizedBox(width: 12),
              
              // Título y Artista
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Botón Play/Pausa
              GestureDetector(
                onTap: notifier.togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: playerState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(
                            playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              
              // Botón Siguiente
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 28,
                color: playerState.hasNext ? Colors.white : Colors.white38,
                onPressed: playerState.hasNext ? () => notifier.playNext() : null,
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Barra de progreso mínima en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double progress = playerState.duration.inMilliseconds > 0
                    ? playerState.position.inMilliseconds / playerState.duration.inMilliseconds
                    : 0.0;
                return Container(
                  height: 3,
                  width: constraints.maxWidth,
                  color: Colors.white12,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 3,
                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                    color: AppTheme.accent,
                  ),
                );
              }
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppTheme.bgSurface,
      child: const Icon(Icons.music_note, color: Colors.white24, size: 30),
    );
  }
}
