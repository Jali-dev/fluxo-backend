import 'package:dio/dio.dart';

class FacebookClientExtractor {
  final Dio _dio = Dio();

  FacebookClientExtractor() {
    _dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Upgrade-Insecure-Requests': '1',
    };
    // Deshabilitar redirecciones automáticas a veces ayuda a no caer en loops de login,
    // pero para FB public suele ser mejor seguirlas. Lo dejaremos por defecto (true).
  }

  /// Intenta extraer la URL directa del video (mp4 o mpd) parseando el HTML.
  Future<String?> extractVideoUrl(String postUrl) async {
    try {
      // 1. Obtener el HTML de la página
      final response = await _dio.get(postUrl);
      if (response.statusCode != 200) {
        print("FacebookClientExtractor: Error HTTP ${response.statusCode}");
        return null;
      }

      final String html = response.data.toString();

      // 2. Buscar patrones de video (Prioridad: HD -> SD -> DASH -> HLS)
      
      // Patrón para HD mp4
      String? videoUrl = _findMatch(html, r'"playable_url_quality_hd":"([^"]+)"');
      if (videoUrl != null) return _cleanUrl(videoUrl);

      // Patrón para SD mp4
      videoUrl = _findMatch(html, r'"playable_url":"([^"]+)"');
      if (videoUrl != null) return _cleanUrl(videoUrl);

      // Patrón Alternativo (Graph API format en source code)
      videoUrl = _findMatch(html, r'"hd_src":"([^"]+)"');
      if (videoUrl != null) return _cleanUrl(videoUrl);
      
      videoUrl = _findMatch(html, r'"sd_src":"([^"]+)"');
      if (videoUrl != null) return _cleanUrl(videoUrl);

      // Patrón DASH (.mpd) - Común en Lives
      // Facebook mete el XML dentro de un string JSON escapado.
      String? dashManifest = _findMatch(html, r'"dash_manifest":"([^"]+)"');
      if (dashManifest != null) {
        // En este caso, FB suele entregar el XML escapado. 
        // Chromecast necesita una URL .mpd. 
        // A veces esto no es una URL, sino el XML crudo.
        // Si es XML crudo, NO nos sirve para Chromecast directamente sin un servidor local.
        // Pero veamos si hay una URL.
        if (dashManifest.startsWith("http")) {
             return _cleanUrl(dashManifest);
        }
        // Si no es URL, intentar buscar hls_manifest que sí suele ser URL.
      }

      // Patrón HLS (.m3u8) - Mejor soporte en Chromecast
      String? hlsManifest = _findMatch(html, r'"hls_manifest":"([^"]+)"');
       if (hlsManifest != null) {
         return _cleanUrl(hlsManifest);
       }
      
      return null;

    } catch (e) {
      print("FacebookClientExtractor: Exception $e");
      return null;
    }
  }

  String? _findMatch(String content, String regexPattern) {
    final RegExp regExp = RegExp(regexPattern);
    final Match? match = regExp.firstMatch(content);
    return match?.group(1);
  }

  String _cleanUrl(String url) {
    // Facebook escapa los slashes como \/
    return url.replaceAll(r'\/', '/').replaceAll(r'\u0025', '%').replaceAll(r'\u0026', '&');
  }
}
