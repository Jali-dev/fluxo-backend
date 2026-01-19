import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/features/home/domain/repositories/video_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final VideoRepository repository;

  HomeCubit({required this.repository}) : super(HomeInitial());

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
