import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../api/image_proxy.dart';
import 'download_button.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool compact;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgCard, Color(0xFF16162A)],
          ),
          border: Border.all(color: AppTheme.divider, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppTheme.accent.withOpacity(0.1),
              highlightColor: AppTheme.accent.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Thumbnail
                    _buildThumbnail(),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(child: _buildInfo(context)),
                    // Download button
                    DownloadButton(
                      videoId: song.videoId,
                      title: song.title,
                      artist: song.artist,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final proxiedUrl = proxyImageUrl(song.thumbnail);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: proxiedUrl != null
          ? CachedNetworkImage(
              imageUrl: proxiedUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => _shimmerBox(56, 56),
              errorWidget: (_, __, ___) => _placeholderIcon(),
            )
          : _placeholderIcon(),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          song.artist,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (song.album != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.album_rounded, size: 11, color: AppTheme.textSecondary),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  song.album!,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (song.duration != null) ...[
                const SizedBox(width: 8),
                Text(
                  song.duration!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _shimmerBox(double w, double h) => Shimmer.fromColors(
        baseColor: AppTheme.bgCard,
        highlightColor: AppTheme.bgSurface,
        child: Container(width: w, height: h, color: AppTheme.bgCard),
      );

  Widget _placeholderIcon() => Container(
        width: 56,
        height: 56,
        color: AppTheme.bgSurface,
        child: const Icon(
          Icons.music_note_rounded,
          color: AppTheme.textSecondary,
          size: 24,
        ),
      );
}
