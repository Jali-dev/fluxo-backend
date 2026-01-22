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
    const String apiUrl = AppConstants.kBackendUrl; 
    
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception("El servidor tardó demasiado (Timeout). Intenta con un video más corto.");
      } else if (e.response != null) {
        // Backend returned an error (400, 422, 500)
        final errorMsg = e.response?.data['error'] ?? 'Error desconocido del servidor';
        throw Exception(errorMsg);
      } else {
        throw Exception("Error de conexión: Verifica tu internet.");
      }
    } catch (e) {
      throw Exception("Error inesperado: $e");
    }
  }
}
