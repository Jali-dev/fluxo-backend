import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:fluxo/features/home/presentation/bloc/home_cubit.dart';
import 'package:fluxo/features/home/presentation/bloc/home_state.dart';
import 'package:fluxo/features/web_caster/screens/web_caster_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.fluxo.fluxo/cast');
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkInitialLink();
    platform.setMethodCallHandler((call) async {
      if (call.method == "onLinkReceived") {
        debugPrint("Native link received: ${call.arguments}");
        if (call.arguments is String) {
           _processLink(call.arguments);
        }
      }
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialLink() async {
    try {
      final String? url = await platform.invokeMethod('getInitialLink');
      if (url != null && url.isNotEmpty) {
        debugPrint("Initial link found: $url");
        _processLink(url);
      }
    } catch (e) {
      debugPrint("Error checking initial link: $e");
    }
  }

  void _processLink(String link) {
    debugPrint("Link received: $link");
    context.read<HomeCubit>().onLinkReceived(link);
  }

  void _navigateToBrowser() {
    String url = _linkController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith("http")) {
      url = "https://$url";
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => WebCasterScreen(initialUrl: url)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback color
      body: Stack(
        children: [
          // 1. Background Gradients
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(0.3),
                backgroundBlendMode: BlendMode.plus,
                boxShadow: const [BoxShadow(color: Colors.purple, blurRadius: 100, spreadRadius: 50)],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.3),
                backgroundBlendMode: BlendMode.plus,
                boxShadow: const [BoxShadow(color: Colors.blue, blurRadius: 100, spreadRadius: 50)],
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.2),
                backgroundBlendMode: BlendMode.plus,
                boxShadow: const [BoxShadow(color: Colors.green, blurRadius: 100, spreadRadius: 30)],
              ),
            ),
          ),
          
          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) {
                        if (state is HomeInitial) {
                          return _buildInitialView();
                        } else if (state is HomeLoading) {
                          return _buildLoadingView();
                        } else if (state is HomeSniffing) {
                          return _buildSniffingView(state);
                        } else if (state is HomeVideoLoaded) {
                          return _buildVideoLoadedView(context, state);
                        } else if (state is HomeError) {
                           return _buildErrorView(context, state);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Fluxo Player',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10)],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.public, color: Colors.greenAccent),
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const WebCasterScreen()));
                },
                tooltip: "Navegador Web",
              ),
              IconButton(
                icon: const Icon(Icons.cast, color: Colors.white),
                onPressed: () {
                   _HomePageState.platform.invokeMethod('showRouteSelector');
                },
                tooltip: "Conectar a TV",
              ),
               Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange.withOpacity(0.8), Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)]
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  onPressed: () {
                     // TODO: Implement share functionality
                  },
                  tooltip: "Compartir",
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Search Bar Container with Gradient Border
        Container(
          padding: const EdgeInsets.all(2), // Border width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple]),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(28),
            ),
            child: TextField(
              controller: _linkController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Pega tu enlace aquí...",
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onSubmitted: (_) => _navigateToBrowser(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Play Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text(
              "REPRODUCIR",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF536DFE), // Blue-ish purple
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              shadowColor: const Color(0xFF536DFE).withOpacity(0.5),
            ),
            onPressed: _navigateToBrowser,
          ),
        ),
        
        const SizedBox(height: 32),
        const Text(
          'Comparte un enlace de Facebook con Fluxo para comenzar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blueAccent),
          SizedBox(height: 16),
          Text('Extrayendo video...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSniffingView(HomeSniffing state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 16),
          Text(state.message, style: const TextStyle(color: Colors.orange)),
          const SizedBox(height: 8),
          const Text("Activando modo 'Sniffer' invisible...", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildVideoLoadedView(BuildContext context, HomeVideoLoaded state) {
    final video = state.video;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
              image: video.thumbnail.isNotEmpty
                  ? DecorationImage(image: NetworkImage(video.thumbnail), fit: BoxFit.cover)
                  : null,
            ),
            child: video.thumbnail.isEmpty
                ? const Icon(Icons.movie_creation_outlined, size: 80, color: Colors.white54)
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            video.title.isEmpty ? "Video Detectado" : video.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(video.type.toUpperCase()),
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            labelStyle: const TextStyle(color: Colors.blueAccent),
            side: BorderSide.none,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cast_connected),
              label: const Text("ENVIAR A LA TV", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: () => context.read<HomeCubit>().loadVideoToCast(),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 40, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, size: 32, color: Colors.redAccent),
                onPressed: () => context.read<HomeCubit>().stopCast(),
                tooltip: "Detener",
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.play_circle_fill, size: 48, color: Colors.blue),
                onPressed: () => context.read<HomeCubit>().playCast(),
                tooltip: "Reproducir",
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.pause_circle_outlined, size: 32, color: Colors.white70),
                onPressed: () => context.read<HomeCubit>().pauseCast(),
                tooltip: "Pausar",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, HomeError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.read<HomeCubit>().retry(),
            child: const Text('Intentar de nuevo'),
          ),
           const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.open_in_browser, color: Colors.blueAccent),
              label: const Text('Probar Navegador Web', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                final link = context.read<HomeCubit>().currentLink;
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => WebCasterScreen(
                      initialUrl: link ?? "https://librefutboltv.su/home/directv-sports/"
                    )
                  )
                );
              },
            )
        ],
      ),
    );
  }
}

