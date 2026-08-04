import 'song.dart';

class Album {
  final String? browseId;
  final String title;
  final String artist;
  final String? year;
  final String? thumbnail;

  const Album({
    this.browseId,
    required this.title,
    required this.artist,
    this.year,
    this.thumbnail,
  });

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        browseId: json['browseId'] as String?,
        title: json['title'] as String? ?? 'Sin título',
        artist: json['artist'] as String? ?? 'Desconocido',
        year: json['year']?.toString(),
        thumbnail: json['thumbnail'] as String?,
      );
}

class AlbumDetail extends Album {
  final String? description;
  final int? trackCount;
  final String? duration;
  final List<Song> tracks;

  const AlbumDetail({
    super.browseId,
    required super.title,
    required super.artist,
    super.year,
    super.thumbnail,
    this.description,
    this.trackCount,
    this.duration,
    required this.tracks,
  });

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    final trackList = (json['tracks'] as List? ?? [])
        .map((t) => Song.fromJson(t as Map<String, dynamic>))
        .toList();
    return AlbumDetail(
      browseId: json['browseId'] as String?,
      title: json['title'] as String? ?? 'Sin título',
      artist: json['artist'] as String? ?? 'Desconocido',
      year: json['year']?.toString(),
      thumbnail: json['thumbnail'] as String?,
      description: json['description'] as String?,
      trackCount: json['trackCount'] as int?,
      duration: json['duration'] as String?,
      tracks: trackList,
    );
  }
}
