class Song {
  final String? videoId;
  final String title;
  final String artist;
  final String? album;
  final String? duration;
  final String? thumbnail;
  final int? trackNumber;

  const Song({
    this.videoId,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.thumbnail,
    this.trackNumber,
  });

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        videoId: json['videoId'] as String?,
        title: json['title'] as String? ?? 'Sin título',
        artist: json['artist'] as String? ?? 'Desconocido',
        album: json['album'] as String?,
        duration: json['duration'] as String?,
        thumbnail: json['thumbnail'] as String?,
        trackNumber: json['trackNumber'] as int?,
      );

  bool get canDownload => videoId != null && videoId!.isNotEmpty;
}
