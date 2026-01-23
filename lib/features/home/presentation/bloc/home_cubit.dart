import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/services/cast_service.dart';
import 'package:fluxo/features/home/domain/repositories/video_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final VideoRepository repository;


  final CastService _castService = CastService(); // Simple instance for now, or inject it

  HomeCubit({required this.repository}) : super(HomeInitial());

  // ... (previous methods)

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
  String? _lastLink;
  
  Future<void> onLinkReceived(String link) async {
    _lastLink = link;
    try {
      emit(HomeLoading());
      
      // Extract URL from text (Facebook often sends "Watch this video... https://...")
      final RegExp urlRegExp = RegExp(
        r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)?',
        caseSensitive: false,
      );
      
      final String? cleanUrl = urlRegExp.firstMatch(link)?.group(0);
      
      if (cleanUrl == null) {
        throw Exception("No valid URL found in the shared text");
      }
      
      final video = await repository.extractVideo(cleanUrl);
      emit(HomeVideoLoaded(video));
      
      // Auto-load to Cast if connected
      try {
        await _castService.loadMedia(
          url: video.directUrl,
          title: video.title,
          imageUrl: video.thumbnail,
          contentType: 'video/mp4', // Adjust if needed based on video.type or metadata
        );
      } catch (e) {
        // Ignore cast errors if not connected, user can connect manually and we might need a "Cast Now" button
        print("Auto-cast failed (likely not connected): $e");
      }
    } catch (e) {
      emit(HomeError("Error extracting video: $e"));
    }
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
