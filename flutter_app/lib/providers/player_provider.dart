import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../api/config.dart';

class PlayerStateData {
  final Song? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final List<Song> queue;
  final int currentIndex;

  const PlayerStateData({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
  });

  PlayerStateData copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    int? currentIndex,
  }) {
    return PlayerStateData(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;
}

class PlayerNotifier extends StateNotifier<PlayerStateData> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  PlayerNotifier() : super(const PlayerStateData()) {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        state = state.copyWith(isLoading: true, isPlaying: isPlaying);
      } else if (processingState == ProcessingState.completed) {
        state = state.copyWith(isLoading: false, isPlaying: false, position: Duration.zero);
        // Auto-avanzar a la siguiente canción
        if (state.hasNext) {
          playNext();
        } else {
          _audioPlayer.pause();
          _audioPlayer.seek(Duration.zero);
        }
      } else {
        state = state.copyWith(isLoading: false, isPlaying: isPlaying);
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  /// Obtiene la URL del audio cacheado en nuestro backend.
  /// Primero hace un "warmup" al proxy de streaming para que yt-dlp
  /// extraiga la URL directa antes de que just_audio intente cargarla.
  Future<String?> _fetchStreamUrl(String videoId) async {
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/stream/url/$videoId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'] as String?;
        if (url != null) {
          final fullUrl = url.startsWith('http') ? url : '$kBaseUrl$url';

          // Warmup: hacer una petición Range mínima al proxy para forzar
          // que yt-dlp extraiga la URL directa ANTES de que just_audio la pida.
          // Esto evita el error "(4) Failed to load URL" por timeout.
          try {
            final warmup = await http.get(
              Uri.parse(fullUrl),
              headers: {'Range': 'bytes=0-1'},
            ).timeout(const Duration(seconds: 90));
            print("Stream warmup status: ${warmup.statusCode}");
          } catch (e) {
            print("Stream warmup warning (continuando igualmente): $e");
          }

          return fullUrl;
        }
      }
    } catch (e) {
      print("Error al obtener URL de stream: $e");
    }
    return null;
  }

  /// Reproduce una canción individual (sin cola).
  Future<void> playSong(Song song) async {
    if (song.videoId == null) return;

    await _audioPlayer.stop();

    state = state.copyWith(
      currentSong: song,
      isLoading: true,
      position: Duration.zero,
      duration: Duration.zero,
    );

    try {
      final streamUrl = await _fetchStreamUrl(song.videoId!);
      if (streamUrl == null) {
        state = state.copyWith(isLoading: false, isPlaying: false);
        return;
      }
      await _audioPlayer.setUrl(streamUrl);
      _audioPlayer.play();
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false);
      print("Error al reproducir: $e");
    }
  }

  /// Reproduce una canción desde una cola (lista de canciones).
  Future<void> playFromQueue(List<Song> queue, int index) async {
    if (index < 0 || index >= queue.length) return;
    final song = queue[index];
    if (song.videoId == null) return;

    await _audioPlayer.stop();

    state = state.copyWith(
      queue: queue,
      currentIndex: index,
      currentSong: song,
      isLoading: true,
      position: Duration.zero,
      duration: Duration.zero,
    );

    try {
      final streamUrl = await _fetchStreamUrl(song.videoId!);
      if (streamUrl == null) {
        state = state.copyWith(isLoading: false, isPlaying: false);
        return;
      }
      await _audioPlayer.setUrl(streamUrl);
      _audioPlayer.play();
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false);
      print("Error al reproducir: $e");
    }
  }

  /// Avanza a la siguiente canción de la cola.
  Future<void> playNext() async {
    if (!state.hasNext) return;
    await playFromQueue(state.queue, state.currentIndex + 1);
  }

  /// Retrocede a la canción anterior de la cola.
  /// Si la posición actual es mayor a 3 segundos, reinicia la canción actual.
  Future<void> playPrevious() async {
    if (state.position.inSeconds > 3) {
      // Reiniciar la canción actual
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    if (!state.hasPrevious) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    await playFromQueue(state.queue, state.currentIndex - 1);
  }

  void togglePlayPause() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void setVolume(double volume) {
    _audioPlayer.setVolume(volume);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerStateData>((ref) {
  return PlayerNotifier();
});
