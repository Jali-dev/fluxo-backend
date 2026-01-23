import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SnifferService {
  HeadlessInAppWebView? _headlessWebView;
  
  /// Intenta "olfatear" una URL de video (m3u8 o mp4) navegando a la [pageUrl].
  /// Retorna la URL del video encontrado o null si falla tras [timeout] segundos.
  Future<String?> sniffVideo(String pageUrl, {Duration timeout = const Duration(seconds: 15)}) async {
    final Completer<String?> completer = Completer();
    
    // Timer para el timeout
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
        _dispose();
      }
    });

    try {
      _headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(pageUrl)),
        initialSettings: InAppWebViewSettings(
          isInspectable: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useShouldInterceptRequest: true, // Importante para interceptar
          userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36", // Mobile User Agent
        ),
        onWebViewCreated: (controller) {
          // print("Sniffer: WebView Created");
        },
        onLoadStart: (controller, url) {
           // print("Sniffer: Loading $url");
        },
        onLoadStop: (controller, url) async {
           // print("Sniffer: Load Stopped $url");
           // A veces es necesario ejecutar JS para forzar la reproducción
           /*
           await controller.evaluateJavascript(source: """
             var videos = document.getElementsByTagName('video');
             if(videos.length > 0) { videos[0].play(); }
           """);
           */
        },
        shouldInterceptRequest: (controller, request) async {
          final String url = request.url.toString();
          
          // Filtros para detectar video streams
          if (_isVideoUrl(url)) {
            if (!completer.isCompleted) {
              // print("Sniffer: VIDEO FOUND! $url");
              completer.complete(url);
              timer.cancel();
              // No disponemos inmediatamente para evitar crashes si el webview sigue haciendo cosas
             Future.delayed(const Duration(seconds: 1), _dispose); 
            }
          }
          return null;
        },
        onConsoleMessage: (controller, consoleMessage) {
          // print("Sniffer Console: ${consoleMessage.message}");
        },
      );

      await _headlessWebView?.run();
      
      return await completer.future;
    } catch (e) {
      print("Sniffer Error: $e");
      if (!completer.isCompleted) completer.complete(null);
      return null;
    }
  }

  bool _isVideoUrl(String url) {
    // 1. Filtro Negativo Estricto: Si es un asset estático, RECHAZAR inmediatamente.
    if (url.contains(".css") || 
        url.contains(".js") || 
        url.contains(".png") || 
        url.contains(".jpg") || 
        url.contains(".gif") || 
        url.contains(".svg") || 
        url.contains(".woff") || 
        url.contains(".ttf") || 
        url.contains(".json") || 
        url.contains(".ico")) {
      return false;
    }

    // 2. Filtro Positivo: Extensiones de Video explícitas
    if (url.contains(".m3u8") || url.contains(".mp4")) {
      return true;
    }

    // 3. Filtro Específico FbCDN (Videos de Facebook)
    // Los videos de FB suelen tener URLs largas sin extensión clara, pero vienen de fbcdn.net
    // y suelen tener parámetros como 'bytestart', 'efg', o 'nc_cat' si son segmentos.
    if (url.contains("fbcdn.net") || url.contains("video-den")) {
       // Verificaciones adicionales para asegurar que es video y no basura
       if (url.contains("bytestart") || 
           url.contains("efg=") || 
           url.contains("oe=") || // Token expiration param often present in media
           url.contains("nc_cat")) {
         return true;
       }
       // Si es fbcdn pero no tiene indicio claro de ser media stream, mejor ser conservador
       // o retornamos true si nos arriesgamos, pero en este caso el .css pasó por aquí.
       // Al haber filtrado .css arriba, es más seguro retornar true aquí si confiamos.
       return true; 
    }
    
    return false;
  }

  void _dispose() {
    try {
      _headlessWebView?.dispose();
      _headlessWebView = null;
    } catch (e) { 
      // Ignore dispose errors
    }
  }
}
