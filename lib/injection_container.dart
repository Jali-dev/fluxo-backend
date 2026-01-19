import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:fluxo/features/home/data/datasources/video_remote_data_source.dart';
import 'package:fluxo/features/home/data/repositories/video_repository_impl.dart';
import 'package:fluxo/features/home/domain/repositories/video_repository.dart';
import 'package:fluxo/features/home/presentation/bloc/home_cubit.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => HomeCubit(repository: sl()));

  // Repositories
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<VideoRemoteDataSource>(
    () => VideoRemoteDataSourceImpl(dio: sl()),
  );

  // External
  sl.registerLazySingleton(() => Dio());
}
