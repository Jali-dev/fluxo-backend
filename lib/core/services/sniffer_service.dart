import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SnifferService {
  HeadlessInAppWebView? _headlessWebView;
  
  /// Intenta "olfatear" una URL de video (m3u8 o mp4) navegando a la [pageUrl].
  /// Retorna la URL del video encontrado o null si falla tras [timeout] segundos.
  Future<String?> sniffVideo(String pageUrl, {Duration timeout = const Duration(seconds: 25)}) async {
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
           // Ejecutar JS para forzar la reproducción (necesario para VODs/Lives que no autoinician)
           try {
             await controller.evaluateJavascript(source: """
               var videos = document.getElementsByTagName('video');
               for(var i=0; i<videos.length; i++) {
                 videos[i].muted = true; // Mute required for autoplay usually
                 videos[i].play();
               }
             """);
           } catch (e) {
             // Ignore JS errors
           }
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
    if (url.startsWith("blob:") || url.startsWith("data:")) return false;
    
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

    // 2. Filtro Positivo: Extensiones de Video explícitas (Incluido DASH .mpd)
    if (url.contains(".m3u8") || 
        url.contains(".mp4") || 
        url.contains(".mpd")) {
      return true;
    }

    // 3. Filtro Específico FbCDN (Videos de Facebook)
    // Si la URL viene de los CDNs de video de Facebook y NO es un archivo estático (filtrado arriba),
    // asumimos que es un segmento de video o el stream mismo.
    // Lives suelen usar DASH (.mpd) o segmentos crudos sin extensión clara pero en estos dominios.
    if (url.contains("fbcdn.net") || url.contains("video-den") || url.contains("googlevideo.com")) {
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
