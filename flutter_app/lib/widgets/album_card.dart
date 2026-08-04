import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/album.dart';
import '../theme/app_theme.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;

  const AlbumCard({super.key, required this.album, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.bgCard,
          border: Border.all(color: AppTheme.divider, width: 0.8),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada del álbum
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: album.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: album.thumbnail!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: AppTheme.bgCard,
                          highlightColor: AppTheme.bgSurface,
                          child: Container(color: AppTheme.bgCard),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${album.artist}${album.year != null ? ' · ${album.year}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.bgSurface,
        child: const Center(
          child: Icon(Icons.album_rounded, color: AppTheme.textSecondary, size: 40),
        ),
      );
}
