import 'config.dart';

/// Convierte una URL de thumbnail de YouTube en una URL proxy
/// que pasa por nuestro backend para evitar problemas de CORS.
String? proxyImageUrl(String? originalUrl) {
  if (originalUrl == null || originalUrl.isEmpty) return null;
  return '$kBaseUrl/proxy/image?url=${Uri.encodeComponent(originalUrl)}';
}
