import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:fluxo/core/services/cast_service.dart';
import 'package:fluxo/features/home/data/datasources/video_remote_data_source.dart';
import 'package:fluxo/features/home/data/repositories/video_repository_impl.dart';
import 'package:fluxo/features/home/domain/repositories/video_repository.dart';
import 'package:fluxo/features/home/presentation/bloc/home_cubit.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => HomeCubit(repository: sl()));

  // Services
  sl.registerLazySingleton(() => CastService());

  // Repositories
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<VideoRemoteDataSource>(
    () => VideoRemoteDataSourceImpl(dio: sl()),
  );

  // External
  // External - HTTP Client with Timeout configuration
  sl.registerLazySingleton(() {
    final options = BaseOptions(
      connectTimeout: const Duration(seconds: 10), // Connection handshake
      receiveTimeout: const Duration(seconds: 120), // Waiting for massive extraction
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    return Dio(options);
  });
}
