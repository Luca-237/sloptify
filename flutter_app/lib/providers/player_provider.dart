import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../api/config.dart';

class PlayerStateData {
  final Song? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;

  const PlayerStateData({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  PlayerStateData copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerStateData(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
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
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
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

  Future<void> playSong(Song song) async {
    if (song.videoId == null) return;

    state = state.copyWith(currentSong: song, isLoading: true, position: Duration.zero);
    try {
      final streamUrl = '$kBaseUrl/stream/${song.videoId}';
      await _audioPlayer.setUrl(streamUrl);
      _audioPlayer.play();
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false);
      print("Error al reproducir: $e");
    }
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
