import 'package:fluxo/features/home/domain/entities/video_entity.dart';

class VideoModel extends VideoEntity {
  const VideoModel({
    required super.title,
    required super.thumbnail,
    required super.directUrl,
    required super.type,
    super.duration,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      title: json['title'] ?? 'Unknown Title',
      thumbnail: json['thumbnail'] ?? '',
      directUrl: json['direct_url'] ?? '',
      type: json['type'] ?? 'unknown',
      duration: json['duration'] is int ? json['duration'] : null,
    );
  }
}
