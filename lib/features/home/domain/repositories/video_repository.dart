import 'package:fluxo/features/home/domain/entities/video_entity.dart';

abstract class VideoRepository {
  Future<VideoEntity> extractVideo(String socialUrl);
}
