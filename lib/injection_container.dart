import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'features/youtube/data/datasources/youtube_remote_datasource.dart';
import 'features/youtube/data/repositories/youtube_repository_impl.dart';
import 'features/youtube/domain/entities/channel.dart';
import 'features/youtube/domain/entities/video.dart';
import 'features/youtube/domain/repositories/youtube_repository.dart';
import 'features/shorts/domain/usecases/get_shorts_feed.dart';
import 'features/shorts/presentation/bloc/shorts_cubit.dart';
import 'features/youtube/domain/usecases/get_comments.dart';
import 'features/youtube/domain/usecases/get_details.dart';
import 'features/youtube/domain/usecases/get_trending_videos.dart';
import 'features/youtube/domain/usecases/search_videos.dart';
import 'features/youtube/presentation/bloc/channel_cubit.dart';
import 'features/youtube/presentation/bloc/comments_cubit.dart';
import 'features/youtube/presentation/bloc/video_detail_cubit.dart';
import 'features/youtube/presentation/bloc/youtube_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC / Cubit
  sl.registerFactory(
    () => YoutubeBloc(
      getTrendingVideos: sl(),
      searchVideos: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerFactoryParam<VideoDetailCubit, Video, void>(
    (video, _) => VideoDetailCubit(
      initialVideo: video,
      getVideoDetails: sl(),
      getChannelDetails: sl(),
    ),
  );
  sl.registerFactoryParam<ChannelCubit, String, Channel?>(
    (channelId, seed) => ChannelCubit(
      channelId: channelId,
      seedChannel: seed,
      getChannelDetails: sl(),
      getChannelVideos: sl(),
    ),
  );
  sl.registerFactoryParam<CommentsCubit, String, void>(
    (videoId, _) => CommentsCubit(
      videoId: videoId,
      getVideoComments: sl(),
    ),
  );
  sl.registerFactory(() => ShortsCubit(getShortsFeed: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetTrendingVideos(sl()));
  sl.registerLazySingleton(() => SearchVideos(sl()));
  sl.registerLazySingleton(() => GetVideoDetails(sl()));
  sl.registerLazySingleton(() => GetChannelDetails(sl()));
  sl.registerLazySingleton(() => GetChannelVideos(sl()));
  sl.registerLazySingleton(() => GetVideoComments(sl()));
  sl.registerLazySingleton(() => GetShortsFeed(sl()));

  // Repository
  sl.registerLazySingleton<YoutubeRepository>(
    () => YoutubeRepositoryImpl(remoteDatasource: sl()),
  );

  // Data sources
  sl.registerLazySingleton(() => YoutubeRemoteDatasource(apiClient: sl()));

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => ApiClient(client: sl()));
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());
}
