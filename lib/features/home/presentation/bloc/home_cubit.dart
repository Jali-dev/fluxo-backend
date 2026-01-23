import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/services/cast_service.dart';
import 'package:fluxo/core/services/sniffer_service.dart';
import 'package:fluxo/features/home/domain/entities/video_entity.dart';
import 'package:fluxo/features/home/domain/repositories/video_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final VideoRepository repository;
  final CastService _castService = CastService();
  final SnifferService _snifferService = SnifferService();

  HomeCubit({required this.repository}) : super(HomeInitial());

  String? _lastLink;

  Future<void> onLinkReceived(String link) async {
    _lastLink = link;
    try {
      emit(HomeLoading());
      
      // Extract URL from text
      final RegExp urlRegExp = RegExp(
        r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)?',
        caseSensitive: false,
      );
      
      final String? cleanUrl = urlRegExp.firstMatch(link)?.group(0);
      
      if (cleanUrl == null) {
        throw Exception("No valid URL found in the shared text");
      }
      
      VideoEntity? video;
      
      // 1. Try Standard API Extraction
      try {
        video = await repository.extractVideo(cleanUrl);
      } catch (e) {
        print("Standard extraction failed: $e. Switching to Sniffer Mode.");
      }

      // 2. Fallback: Sniffer Mode
      if (video == null) {
        emit(const HomeSniffing("Buscando señal de video en la web..."));
        final String? sniffedUrl = await _snifferService.sniffVideo(cleanUrl);
        
        if (sniffedUrl != null) {
          video = VideoEntity(
            title: "Video Detectado (Live)",
            thumbnail: "", // No thumb in sniff mode usually
            directUrl: sniffedUrl,
            type: "video",
          );
        } else {
           throw Exception("No se pudo extraer el video ni con modo Web.");
        }
      }

      emit(HomeVideoLoaded(video!));
      
      // Auto-load to Cast if connected
      try {
        await _castService.loadMedia(
          url: video.directUrl,
          title: video.title,
          imageUrl: video.thumbnail,
          contentType: 'video/mp4',
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
