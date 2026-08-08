import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../api/image_proxy.dart';
import 'download_button.dart';

class FullScreenPlayer extends ConsumerWidget {
  const FullScreenPlayer({super.key});

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
      color: AppTheme.bgDeep, // Fondo oscuro completo
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: SafeArea(
        child: Column(
          children: [
            // Header con botón para bajar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Portada
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: song?.thumbnail != null
                          ? CachedNetworkImage(
                              imageUrl: proxyImageUrl(song!.thumbnail!)!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(Icons.music_note, size: 80, color: Colors.white24),
                            )
                          : const Icon(Icons.music_note, size: 100, color: Colors.white24),
                    ),
                    const SizedBox(height: 40),
                    
                    // Info de la canción
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            song?.title ?? 'Sin reproducir',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            song?.artist ?? '-',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Barra de progreso
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                              value: playerState.duration.inMilliseconds > 0
                                  ? playerState.position.inMilliseconds.toDouble().clamp(0.0, playerState.duration.inMilliseconds.toDouble())
                                  : 0.0,
                              max: playerState.duration.inMilliseconds > 0
                                  ? playerState.duration.inMilliseconds.toDouble()
                                  : 1.0,
                              onChanged: (val) {
                                notifier.seek(Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(playerState.position), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                Text(_formatDuration(playerState.duration), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Controles de reproducción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          iconSize: 42,
                          color: playerState.hasPrevious || (song != null && playerState.position.inSeconds > 3)
                              ? Colors.white
                              : Colors.white38,
                          onPressed: song != null ? () => notifier.playPrevious() : null,
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: song != null ? notifier.togglePlayPause : null,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accent,
                              boxShadow: [
                                BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
                              ],
                            ),
                            child: Center(
                              child: playerState.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Icon(
                                      playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 42,
                          color: playerState.hasNext ? Colors.white : Colors.white38,
                          onPressed: song != null && playerState.hasNext ? () => notifier.playNext() : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // Botón de descarga
                    if (song != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: DownloadButton(
                          key: ValueKey('fullscreen-dl-${song.videoId}'),
                          videoId: song.videoId,
                          title: song.title,
                          artist: song.artist,
                          size: 64, // Un poco más grande para móvil
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
