import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import '../models/song.dart';
import '../models/album.dart';

class MusicApiException implements Exception {
  final String message;
  final int? statusCode;
  MusicApiException(this.message, {this.statusCode});
  @override
  String toString() => 'MusicApiException: $message (status: $statusCode)';
}

class MusicApi {
  static final MusicApi _instance = MusicApi._internal();
  factory MusicApi() => _instance;
  MusicApi._internal();

  final _client = http.Client();

  Uri _uri(String path, [Map<String, String>? params]) =>
      Uri.parse('$kBaseUrl$path').replace(queryParameters: params);

  Future<dynamic> _get(String path, [Map<String, String>? params]) async {
    try {
      final res = await _client.get(_uri(path, params));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      throw MusicApiException(
        'Error del servidor: ${res.body}',
        statusCode: res.statusCode,
      );
    } on MusicApiException {
      rethrow;
    } catch (e) {
      throw MusicApiException('No se pudo conectar al servidor: $e');
    }
  }

  // ── Búsqueda ────────────────────────────────────────────────
  Future<List<Song>> searchSongs(String query) async {
    final data = await _get('/search/songs', {'q': query});
    final list = data['results'] as List? ?? [];
    return list.map((j) => Song.fromJson(j)).toList();
  }

  Future<List<Album>> searchAlbums(String query) async {
    final data = await _get('/search/albums', {'q': query});
    final list = data['results'] as List? ?? [];
    return list.map((j) => Album.fromJson(j)).toList();
  }

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final data = await _get('/search/all', {'q': query});
    return List<Map<String, dynamic>>.from(data['results'] ?? []);
  }

  // ── Álbum ───────────────────────────────────────────────────
  Future<AlbumDetail> getAlbum(String browseId) async {
    final data = await _get('/album/$browseId');
    return AlbumDetail.fromJson(data);
  }

  // ── Descarga ────────────────────────────────────────────────
  Future<String> requestDownload(String videoId, String title, String artist) async {
    try {
      final res = await _client.post(
        _uri('/download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'videoId': videoId, 'title': title, 'artist': artist}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final downloadUrl = data['downloadUrl'] as String;
        return '$kBaseUrl$downloadUrl';
      }
      throw MusicApiException('Error al descargar', statusCode: res.statusCode);
    } on MusicApiException {
      rethrow;
    } catch (e) {
      throw MusicApiException('Error de conexión: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      // Render free tier puede demorar hasta 50s en despertar (cold start)
      final res = await _client.get(_uri('/')).timeout(
        const Duration(seconds: 60),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
