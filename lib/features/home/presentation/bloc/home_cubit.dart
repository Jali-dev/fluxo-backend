import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/services/cast_service.dart';
import 'package:fluxo/core/services/sniffer_service.dart';
import 'package:fluxo/core/services/facebook_client_extractor.dart';
import 'package:fluxo/features/home/domain/entities/video_entity.dart';
import 'package:fluxo/features/home/domain/repositories/video_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final VideoRepository repository;
  final CastService _castService = CastService();
  final SnifferService _snifferService = SnifferService();
  final FacebookClientExtractor _clientExtractor = FacebookClientExtractor();

  HomeCubit({required this.repository}) : super(HomeInitial());

  String? _lastLink;
  String? get currentLink => _lastLink;

  Future<void> onLinkReceived(String link) async {
    _lastLink = link;
    try {
      emit(HomeLoading());
      
      // Extract URL from text
      // Extract URL from text
      // Usamos un regex más simple pero permisivo para capturar la URL completa con parámetros
      final RegExp urlRegExp = RegExp(
        r'https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://[^\s]+',
        caseSensitive: false,
      );
      
      String? cleanUrl = urlRegExp.firstMatch(link)?.group(0);
      
      // Cleanup cleanup (trailing chars often captured by assertive regexes)
      if (cleanUrl != null && (cleanUrl.endsWith(".") || cleanUrl.endsWith(")"))) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
      
      if (cleanUrl == null) {
        throw Exception("No valid URL found in the shared text");
      }
      
      VideoEntity? video;
      
      // 1. Try Standard API Extraction
      try {
        video = await repository.extractVideo(cleanUrl);
      } catch (e) {
        print("Standard extraction failed: $e. Switching to Fallbacks.");
      }

      // 2. Fallback A: Client-Side Extraction (HTML Parsing)
      if (video == null) {
         emit(const HomeSniffing("Analizando código fuente de la página..."));
         try {
           final String? extractedUrl = await _clientExtractor.extractVideoUrl(cleanUrl);
           if (extractedUrl != null) {
              video = VideoEntity(
                title: "Video Detectado (Nativo)",
                thumbnail: "", 
                directUrl: extractedUrl,
                type: "video",
              );
              print("Client Extractor Found URL: $extractedUrl");
           }
         } catch (e) {
           print("Client Extractor failed: $e");
         }
      }

      // 3. Fallback B: Sniffer Mode (WebView) - Last Resort
      if (video == null) {
        emit(const HomeSniffing("Buscando señal de video en la web (Modo Sniffer)..."));
        final String? sniffedUrl = await _snifferService.sniffVideo(cleanUrl);
        
        if (sniffedUrl != null) {
          video = VideoEntity(
            title: "Video Detectado (Live)",
            thumbnail: "", // No thumb in sniff mode usually
            directUrl: sniffedUrl,
            type: "video",
          );
        } else {
           throw Exception("No se pudo extraer el video con ningún método.");
        }
      }

      emit(HomeVideoLoaded(video!));
      
      // Auto-load to Cast if connected
      try {
        await _castService.loadMedia(
          url: video.directUrl,
          title: video.title,
          imageUrl: video.thumbnail,
          contentType: video.directUrl.contains('.m3u8') 
            ? 'application/x-mpegURL' 
            : (video.directUrl.contains('.mpd') ? 'application/dash+xml' : 'video/mp4'),
        );
      } catch (e) {
        print("Auto-cast failed: $e");
      }
    } catch (e) {
      emit(HomeError("Error extracting video: $e"));
    }
  }

  Future<void> stopCast() async {
    await _castService.stop();
  }

  Future<void> pauseCast() async {
    await _castService.pause();
  }

  Future<void> playCast() async {
    await _castService.play();
  }

  Future<void> setVolume(double vol) async {
    await _castService.setVolume(vol);
  }

  Future<void> loadVideoToCast() async {
    final state = this.state;
    if (state is HomeVideoLoaded) {
       await _castService.loadMedia(
          url: state.video.directUrl,
          title: state.video.title,
          imageUrl: state.video.thumbnail,
          contentType: state.video.directUrl.contains('.m3u8') 
            ? 'application/x-mpegURL' 
            : (state.video.directUrl.contains('.mpd') ? 'application/dash+xml' : 'video/mp4'),
       );
    }
  }

  void retry() {
    if (_lastLink != null) {
      onLinkReceived(_lastLink!);
    } else {
      reset();
    }
  }

  void reset() {
    _lastLink = null;
    emit(HomeInitial());
  }
}
