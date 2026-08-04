import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import 'download_button.dart';

class SidebarPlayer extends ConsumerWidget {
  const SidebarPlayer({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    final notifier = ref.read(playerProvider.notifier);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Portada
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: song?.thumbnail != null
                ? CachedNetworkImage(
                    imageUrl: song!.thumbnail!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.music_note, size: 80, color: Colors.white24),
                  )
                : const Icon(Icons.music_note, size: 80, color: Colors.white24),
          ),
          const SizedBox(height: 32),
          // Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  song?.title ?? 'Sin reproducir',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  song?.artist ?? '-',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Progreso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.accent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: playerState.position.inSeconds.toDouble().clamp(0.0, playerState.duration.inSeconds.toDouble().clamp(0.1, double.infinity)),
                    max: playerState.duration.inSeconds.toDouble().clamp(0.1, double.infinity),
                    onChanged: (val) {
                      notifier.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(playerState.position), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(_formatDuration(playerState.duration), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 36,
                color: Colors.white,
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: song != null ? notifier.togglePlayPause : null,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent,
                    boxShadow: [
                      BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
                    ],
                  ),
                  child: Center(
                    child: playerState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(
                            playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 36,
                color: Colors.white,
                onPressed: () {},
              ),
            ],
          ),
          const Spacer(),
          // Botón de descarga
          if (song != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: DownloadButton(
                videoId: song.videoId,
                title: song.title,
                artist: song.artist,
                size: 56,
              ),
            ),
        ],
      ),
    );
  }
}
