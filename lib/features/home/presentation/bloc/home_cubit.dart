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
  Future<void> onLinkReceived(String url) async {
    try {
      emit(HomeLoading());
      final video = await repository.extractVideo(url);
      emit(HomeVideoLoaded(video));
    } catch (e) {
      emit(HomeError("Error extracting video: $e"));
    }
  }

  void reset() {
    emit(HomeInitial());
  }
}
