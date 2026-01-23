import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluxo/core/services/cast_service.dart';

class SnifferPage extends StatefulWidget {
  final String initialUrl;

  const SnifferPage({super.key, required this.initialUrl});

  @override
  State<SnifferPage> createState() => _SnifferPageState();
}

class _SnifferPageState extends State<SnifferPage> {
  final CastService _castService = CastService();
  InAppWebViewController? _webViewController;
  String? _detectedVideoUrl;
  bool _isVideoDetected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modo Web Interactivo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useShouldInterceptRequest: true,
              userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            shouldInterceptRequest: (controller, request) async {
              final String url = request.url.toString();
              if (_isVideoUrl(url)) {
                 setState(() {
                   _detectedVideoUrl = url;
                   _isVideoDetected = true;
                 });
              }
              return null;
            },
          ),
          if (_isVideoDetected)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.orange,
                child: ListTile(
                  title: const Text("¡Video Detectado!",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(_detectedVideoUrl ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.cast_connected, color: Colors.white, size: 32),
                    onPressed: _castToTv,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isVideoUrl(String url) {
     if (url.startsWith("blob:") || url.startsWith("data:")) return false;
     if (url.contains(".css") || url.contains(".js") || url.contains(".png") || url.contains(".jpg")) return false; 
     if (url.contains(".m3u8") || url.contains(".mp4") || url.contains(".mpd") || url.contains("fbcdn.net")) {
        // Simple logic: if it looks like video, take it.
        return true;
     }
     return false;
  }

  Future<void> _castToTv() async {
    if (_detectedVideoUrl != null) {
      await _castService.loadMedia(
        url: _detectedVideoUrl!,
        title: "Web Video Stream",
        imageUrl: "",
        contentType: 'video/mp4',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enviando al Cast...")),
        );
      }
    }
  }
}
