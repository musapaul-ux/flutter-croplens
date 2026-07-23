import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The backend stores image paths as relative URLs (e.g. "/uploads/abc.jpg")
/// since it doesn't know what host the client will use to reach it. Image
/// widgets like CachedNetworkImage need a full URL though ("No host specified
/// in URI" is exactly this mismatch). This resolves a relative path into a
/// full URL using the same API_BASE_URL the app already talks to the backend
/// with, so it works correctly on web, emulator, and physical devices alike.
class ImageUrlResolver {
  ImageUrlResolver._();

  static String resolve(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // already a full URL (e.g. a future cloud-storage migration)
    }

    final apiBase = dotenv.env['API_BASE_URL'] ?? '';
    final apiUri = Uri.tryParse(apiBase);
    if (apiUri == null || apiUri.host.isEmpty) return url;

    final origin = Uri(scheme: apiUri.scheme, host: apiUri.host, port: apiUri.port).toString();
    final path = url.startsWith('/') ? url : '/$url';
    return '$origin$path';
  }
}