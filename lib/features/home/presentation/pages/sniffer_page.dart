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
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E), // Dark background
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                     BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, -4)),
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Video Detectado",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Mini preview of URL domain only
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Text("LISTO", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cast_connected, color: Colors.white),
                        label: const Text("ENVIAR A LA TV", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        onPressed: _castToTv,
                      ),
                    ),
                  ],
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
     // Simple logic: if it looks like video, take it.
     // BUT EXCLUDE segments (bytestart/byteend)
     if (url.contains("bytestart") || url.contains("byteend") || url.contains("range=")) return false;

     if (url.contains(".m3u8") || url.contains(".mp4") || url.contains(".mpd") || url.contains("fbcdn.net")) {
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
        contentType: _detectedVideoUrl!.contains('.m3u8') 
            ? 'application/x-mpegURL' 
            : (_detectedVideoUrl!.contains('.mpd') ? 'application/dash+xml' : 'video/mp4'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enviando al Cast...")),
        );
      }
    }
  }
}
