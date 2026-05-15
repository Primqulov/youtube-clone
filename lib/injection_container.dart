import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'core/network/api_client.dart';
import 'features/youtube/data/datasources/youtube_remote_datasource.dart';
import 'features/youtube/data/repositories/youtube_repository_impl.dart';
import 'features/youtube/domain/repositories/youtube_repository.dart';
import 'features/youtube/domain/usecases/get_trending_videos.dart';
import 'features/youtube/domain/usecases/search_videos.dart';
import 'features/youtube/domain/usecases/get_details.dart';
import 'features/youtube/presentation/bloc/youtube_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(
    () => YoutubeBloc(
      getTrendingVideos: sl(),
      searchVideos: sl(),
      getVideoDetails: sl(),
      getChannelDetails: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetTrendingVideos(sl()));
  sl.registerLazySingleton(() => SearchVideos(sl()));
  sl.registerLazySingleton(() => GetVideoDetails(sl()));
  sl.registerLazySingleton(() => GetChannelDetails(sl()));

  // Repository
  sl.registerLazySingleton<YoutubeRepository>(
    () => YoutubeRepositoryImpl(remoteDatasource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton(
    () => YoutubeRemoteDatasource(apiClient: sl()),
  );

  // Core
  sl.registerLazySingleton(() => ApiClient(client: sl()));
  sl.registerLazySingleton(() => http.Client());
}
