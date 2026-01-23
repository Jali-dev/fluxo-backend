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
    // Patrones comunes de video
    if (url.contains(".m3u8") || 
        url.contains(".mp4") || 
        url.contains("video-den") || // Facebook CDN patterns pattern
        url.contains("fbcdn.net")) {
          
       // Filtros negativos (cosas que parecen video pero no son el stream principal)
       if (url.contains("bytestart") && url.contains("byteend")) return true; // Range requests OK
       if (url.contains(".png") || url.contains(".jpg")) return false; 
       
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
