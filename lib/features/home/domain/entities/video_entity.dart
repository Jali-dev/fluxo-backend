import 'package:equatable/equatable.dart';

class VideoEntity extends Equatable {
  final String title;
  final String thumbnail;
  final String directUrl;
  final String type; // 'live' or 'recorded'
  final int? duration;

  const VideoEntity({
    required this.title,
    required this.thumbnail,
    required this.directUrl,
    required this.type,
    this.duration,
  });

  @override
  List<Object?> get props => [title, thumbnail, directUrl, type, duration];
}
