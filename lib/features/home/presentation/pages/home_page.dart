import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receive_sharing_intent_plus/receive_sharing_intent_plus.dart';
import 'package:fluxo/features/home/presentation/bloc/home_cubit.dart';
import 'package:fluxo/features/home/presentation/bloc/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // 1. Listen for links while app is in memory (Warm Start)
    _intentDataStreamSubscription = ReceiveSharingIntentPlus.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
        _processLink(value.first.path);
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // 2. Handle link when app is opened from closed state (Cold Start)
    ReceiveSharingIntentPlus.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
        _processLink(value.first.path);
      }
    });
  }

  void _processLink(String link) {
    debugPrint("Link received: $link");
    context.read<HomeCubit>().onLinkReceived(link);
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fluxo Player')),
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
              } else if (state is HomeVideoLoaded) {
                 final video = state.video;
                 return SingleChildScrollView(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       if (video.thumbnail.isNotEmpty)
                         Image.network(video.thumbnail, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 50)),
                       const SizedBox(height: 20),
                       Text(
                         video.title,
                         style: Theme.of(context).textTheme.headlineSmall,
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 10),
                       Chip(label: Text(video.type.toUpperCase())),
                       const SizedBox(height: 20),
                       Text(
                         'Direct URL:',
                         style: Theme.of(context).textTheme.labelLarge,
                       ),
                       SelectableText(
                         video.directUrl,
                         textAlign: TextAlign.center,
                         style: const TextStyle(color: Colors.blueAccent),
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
                      onPressed: () => context.read<HomeCubit>().reset(),
                      child: const Text('Intentar de nuevo'),
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

