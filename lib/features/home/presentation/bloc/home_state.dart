import 'package:equatable/equatable.dart';
import 'package:fluxo/features/home/domain/entities/video_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeVideoLoaded extends HomeState {
  final VideoEntity video;
  const HomeVideoLoaded(this.video);

  @override
  List<Object?> get props => [video];
}

class HomeSniffing extends HomeState {
  final String message;
  const HomeSniffing(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
