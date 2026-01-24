import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart'; // For MethodChannel
// import 'package:receive_sharing_intent_plus/receive_sharing_intent_plus.dart';
import 'package:fluxo/features/home/presentation/bloc/home_cubit.dart';
import 'package:fluxo/features/home/presentation/bloc/home_state.dart';
import 'package:fluxo/features/home/presentation/pages/sniffer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.fluxo.fluxo/cast');

  @override
  void initState() {
    super.initState();

    // 1. Cold Start: Check if app was opened with a link
    _checkInitialLink();

    // 2. Warm Start: Listen for new links while app is open
    platform.setMethodCallHandler((call) async {
      if (call.method == "onLinkReceived") {
        debugPrint("Native link received: ${call.arguments}");
        if (call.arguments is String) {
           _processLink(call.arguments);
        }
      }
    });
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

  @override
  void dispose() {
    // Remove method call handler? Typically not explicitly needed for singleton widget
    // but good practice if we want to stop listening.
    // platform.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluxo Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () {
               _HomePageState.platform.invokeMethod('showRouteSelector');
            },
            tooltip: "Conectar a TV",
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeInitial) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.share, size: 64, color: Colors.grey),
                     SizedBox(height: 16),
                     Text('Comparte un enlace de Facebook con Fluxo para comenzar.'),
                  ],
                );
              } else if (state is HomeLoading) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Extrayendo video...'),
                  ],
                );
              } else if (state is HomeSniffing) {
                 return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: Colors.orange)),
                    const SizedBox(height: 8),
                    const Text("Activando modo 'Sniffer' invisible...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                );
              } else if (state is HomeVideoLoaded) {
                 final video = state.video;
                 return SingleChildScrollView(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Container(
                         height: 200,
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: Colors.black12,
                           borderRadius: BorderRadius.circular(16),
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
                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 8),
                       Chip(
                         label: Text(video.type.toUpperCase()),
                         backgroundColor: Colors.blueAccent.withOpacity(0.1),
                         labelStyle: const TextStyle(color: Colors.blueAccent),
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
                       // Solo controles básicos si ya está conectado
                       const Divider(height: 40),
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
                             icon: const Icon(Icons.pause_circle_outlined, size: 32),
                             onPressed: () => context.read<HomeCubit>().pauseCast(),
                             tooltip: "Pausar",
                           ),
                         ],
                       ),
                     ],
                   ),
                 );
              } else if (state is HomeError) {
                return Column(
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
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Probar Modo Web Interactivo'),
                      onPressed: () {
                        final link = context.read<HomeCubit>().currentLink;
                        if (link != null) {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => SnifferPage(initialUrl: link)));
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay link disponible")));
                        }
                      },
                    )
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

