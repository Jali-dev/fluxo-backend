import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluxo/core/services/cast_service.dart';
import 'package:fluxo/injection_container.dart';
import 'package:fluxo/core/constants/supported_video_formats.dart';
import 'dart:collection';

class VideoSource {
  final String url;
  final String title;
  final String type; // m3u8, mp4, etc.
  final String resolution; // 720p, 1080p, or "adaptive"

  VideoSource({required this.url, required this.title, required this.type, this.resolution = ""});
  
  @override
  bool operator ==(Object other) => other is VideoSource && other.url == url;
  
  @override
  int get hashCode => url.hashCode;
}

class WebCasterScreen extends StatefulWidget {
  final String initialUrl;

  const WebCasterScreen({
    super.key, 
    this.initialUrl = "https://librefutboltv.su/home/directv-sports/"
  });

  @override
  State<WebCasterScreen> createState() => _WebCasterScreenState();
}

class _WebCasterScreenState extends State<WebCasterScreen> {
  late final CastService _castService;
  late final Dio _dio;
  InAppWebViewController? _webViewController;
  final TextEditingController _urlController = TextEditingController();
  
  // List of unique videos
  final Set<VideoSource> _detectedVideos = {};
  final Set<String> _analyzedUrls = {}; // Cache to avoid re-analyzing
  double _progress = 0;
  String _pageTitle = "Web Page";

  @override
  void initState() {
    super.initState();
    _castService = sl<CastService>();
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
      validateStatus: (status) => status != null && status < 500,
    ));
    _urlController.text = widget.initialUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorador"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () => _castService.showRouteSelector(),
            tooltip: "Dispositivos Cast",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
          // Video Counter Button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.play_circle_outline, size: 30),
                onPressed: () => _showVideoList(),
                tooltip: "Videos Detectados",
              ),
              if (_detectedVideos.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${_detectedVideos.length}",
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'scan') _manualScan();
              if (value == 'clear') setState(() { _detectedVideos.clear(); _analyzedUrls.clear(); });
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'scan',
                  child: Row(children: [Icon(Icons.search, color: Colors.black54), SizedBox(width: 8), Text('Escanear Manualmente')]),
                ),
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(children: [Icon(Icons.cleaning_services, color: Colors.black54), SizedBox(width: 8), Text('Limpiar Lista')]),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Browser Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () async {
                    if (await _webViewController?.canGoBack() ?? false) _webViewController?.goBack();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () async {
                    if (await _webViewController?.canGoForward() ?? false) _webViewController?.goForward();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: "URL...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      var url = value.trim();
                      if (!url.startsWith("http")) url = "https://$url";
                      _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                     var url = _urlController.text.trim();
                     if (!url.startsWith("http")) url = "https://$url";
                     _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
                  },
                ),
              ],
            ),
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(value: _progress, minHeight: 2, color: Colors.yellow),
            
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    useShouldInterceptRequest: true,
                    javaScriptEnabled: true,
                    userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                  ),
                  // MONKEY PATCHING: Inyectar script al inicio para interceptar Fetch y XHR
                  initialUserScripts: UnmodifiableListView<UserScript>([
                    UserScript(
                      source: """
                        (function() {
                            console.log("🔥 FLUXO MONKEY PATCH ACTIVE");
                            
                            // 1. Interceptar FETCH
                            const originalFetch = window.fetch;
                            window.fetch = async function(...args) {
                                const url = args[0] ? args[0].toString() : '';
                                if (url.includes('.m3u8') || url.includes('.mp4') || (url.includes('.ts') && !url.includes('.ts?'))) {
                                    // Comprobación preliminar rápida en JS
                                    window.flutter_inappwebview.callHandler('VideoDetected', url);
                                }
                                return originalFetch.apply(this, args);
                            };

                            // 2. Interceptar XHR
                            const originalOpen = XMLHttpRequest.prototype.open;
                            XMLHttpRequest.prototype.open = function(method, url) {
                                if (typeof url === 'string' && (url.includes('.m3u8') || url.includes('.mp4') || (url.includes('.ts') && !url.includes('.ts?')))) {
                                     window.flutter_inappwebview.callHandler('VideoDetected', url);
                                }
                                return originalOpen.apply(this, arguments);
                            };
                        })();
                      """,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                      forMainFrameOnly: false, // Importante: Interceptar en iframes también
                    )
                  ]),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    
                    // Handler para recibir las URLs interceptadas por el script
                    controller.addJavaScriptHandler(handlerName: 'VideoDetected', callback: (args) {
                      if (args.isNotEmpty) {
                        final String url = args[0].toString();
                        // Enviar a análisis (donde pasará por el filtro estricto y deduplicación)
                        _analyzeUrl(url);
                      }
                    });
                  },
                  onLoadStop: (controller, url) async {
                    _urlController.text = url.toString();
                    String? title = await controller.getTitle();
                    if (title != null) _pageTitle = title;
                  },
                  shouldInterceptRequest: (controller, request) async {
                    // Mantener intercepción pasiva por si acaso
                    final String url = request.url.toString();
                    _analyzeUrl(url);
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Strict Sniffer Logic
  Future<void> _analyzeUrl(String url) async {
    // 1. STRICT BLACKLIST (Fast Fail)
    if (_shouldExclude(url)) return;

    // 2. Blob Exclusion (Chromecast cannot play blobs directly)
    if (url.startsWith("blob:")) return;

    // 3. INTERNAL DEDUPLICATION
    if (_analyzedUrls.contains(url)) return;
    _analyzedUrls.add(url);

    debugPrint("Analyzing Potential Video: $url");
    String detectedType = "";

    // 4. WHITELIST CHECK (Extension OR MIME Type)

    // A) Explicit Extension Check (Only .m3u8 or .mpd)
    if (url.contains(".m3u8")) { 
       detectedType = "m3u8";
    } else if (url.contains(".mpd")) {
       detectedType = "dash";
    }

    // B) MIME Type Check (The Source of Truth)
    if (detectedType.isEmpty) {
      try {
        final response = await _dio.head(url);
        final contentType = response.headers.value('content-type');
        
        if (contentType != null) {
           final ct = contentType.toLowerCase();
           // Use Constants from SupportedVideoFormats
           if (ct.contains(SupportedVideoFormats.appleMpegUrl) || 
               ct.contains(SupportedVideoFormats.mpegUrl)) {
             detectedType = "m3u8";
           } else if (ct.contains(SupportedVideoFormats.dashXml)) {
             detectedType = "dash";
           } else if (ct.startsWith(SupportedVideoFormats.videoPrefix)) {
             detectedType = "mp4";
           }
        }
      } catch (e) {
        // HEAD failed
      }
    }

    // 5. REGISTER (Only if strictly detected)
    if (detectedType.isNotEmpty) {
      bool alreadyAdded = _detectedVideos.any((v) => v.url == url);
      if (!alreadyAdded) {
         _addVideoSource(url, detectedType);
      }
    }
  }

  bool _shouldExclude(String url) {
    if (url.length > 2000) return true; 

    // STRICT: Block all Transport Stream segments unconditionally
    if (url.contains(".ts")) return true;

    // Main Blacklist
    const junkExtensions = [
      ".js", ".css", ".html", ".vtt", ".srt", // Web resources & Subs
      ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", // Images
      ".json", ".xml", // Data
      "google", "facebook", "doubleclick", "analytics" // Ads/Trackers
    ];

    for (var ext in junkExtensions) {
      if (url.contains(ext)) return true;
    }

    return false;
  }

  void _addVideoSource(String url, String type) {
    final video = VideoSource(
      url: url,
      title: _pageTitle,
      type: type,
      resolution: type == "m3u8" ? "Adaptive" : "Video"
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _detectedVideos.add(video);
        });
        
        // Notify only for Master Playlists
        if (type == 'm3u8' || type == 'dash') {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Stream Detectado: ${type.toUpperCase()}"), 
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            )
          );
        }
      }
    });
  }

  Future<void> _manualScan() async {
    // Inject JS to search for video tags
    final result = await _webViewController?.evaluateJavascript(source: """
      (function() {
        var videos = document.getElementsByTagName('video');
        var results = [];
        for(var i=0; i<videos.length; i++) {
           var src = videos[i].currentSrc || videos[i].src;
           if(src) results.push(src);
        }
        return results;
      })();
    """);

    if (result != null && result is List) {
       for (var item in result) {
         if (item is String) _analyzeUrl(item);
       }
    }
  }

  void _showVideoList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Lista de Videos (${_detectedVideos.length})", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: _detectedVideos.isEmpty 
                ? const Center(child: Text("No se han detectado videos aún.", style: TextStyle(color: Colors.white54)))
                : ListView.separated(
                    itemCount: _detectedVideos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final video = _detectedVideos.elementAt(index);
                      return ListTile(
                        tileColor: Colors.black26,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.movie, color: Colors.white, size: 24),
                        ),
                        title: Text(video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.url, style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                                  child: Text(video.type.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                if (video.resolution.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(video.resolution, style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                                ]
                              ],
                            )
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cast_connected, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            _castVideo(video);
                          },
                        ),
                      );
                    },
                  ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _castVideo(VideoSource video) async {
    String contentType = 'video/mp4';
    if (video.type == 'm3u8') contentType = 'application/x-mpegURL';
    if (video.type == 'dash') contentType = 'application/dash+xml';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Conectando: ${video.title}"))
    );

    await _castService.loadMedia(
      url: video.url,
      title: video.title,
      subtitle: video.resolution,
      contentType: contentType,
      isLive: true,
    );
  }
}
