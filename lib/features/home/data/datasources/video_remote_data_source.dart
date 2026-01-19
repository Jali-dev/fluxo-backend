import 'package:dio/dio.dart';
import 'package:fluxo/core/constants/app_constants.dart';
import 'package:fluxo/features/home/data/models/video_model.dart';

abstract class VideoRemoteDataSource {
  Future<VideoModel> extractVideo(String socialUrl);
}

class VideoRemoteDataSourceImpl implements VideoRemoteDataSource {
  final Dio dio;

  VideoRemoteDataSourceImpl({required this.dio});

  @override
  Future<VideoModel> extractVideo(String socialUrl) async {
    // API URL from constants or config.
    // For now we assume a placeholder, user needs to inject the real Koyeb URL.
    final String apiUrl = AppConstants.kBackendUrl; 
    
    if (apiUrl.isEmpty) {
        throw Exception("Backend URL not configured");
    }

    try {
      final response = await dio.post(
        '$apiUrl/extract',
        data: {'url': socialUrl},
      );

      if (response.statusCode == 200) {
        return VideoModel.fromJson(response.data);
      } else {
        throw Exception("Failed to extract video: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
}
