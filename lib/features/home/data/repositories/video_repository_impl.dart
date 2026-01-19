import 'package:fluxo/features/home/data/datasources/video_remote_data_source.dart';
import 'package:fluxo/features/home/domain/entities/video_entity.dart';
import 'package:fluxo/features/home/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoRemoteDataSource remoteDataSource;

  VideoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<VideoEntity> extractVideo(String socialUrl) async {
    return await remoteDataSource.extractVideo(socialUrl);
  }
}
