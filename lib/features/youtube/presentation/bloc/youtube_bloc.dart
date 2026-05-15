import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_trending_videos.dart';
import '../../domain/usecases/search_videos.dart';
import '../../domain/usecases/get_details.dart';
import 'youtube_event.dart';
import 'youtube_state.dart';

class YoutubeBloc extends Bloc<YoutubeEvent, YoutubeState> {
  final GetTrendingVideos getTrendingVideos;
  final SearchVideos searchVideos;
  final GetVideoDetails getVideoDetails;
  final GetChannelDetails getChannelDetails;

  YoutubeBloc({
    required this.getTrendingVideos,
    required this.searchVideos,
    required this.getVideoDetails,
    required this.getChannelDetails,
  }) : super(const YoutubeInitial()) {
    on<LoadTrendingVideos>(_onLoadTrending);
    on<SearchVideosEvent>(_onSearch);
    on<ClearSearch>(_onClearSearch);
    on<LoadVideoDetails>(_onLoadVideoDetails);
  }

  Future<void> _onLoadTrending(
    LoadTrendingVideos event,
    Emitter<YoutubeState> emit,
  ) async {
    emit(const YoutubeLoading());
    try {
      final videos = await getTrendingVideos();
      emit(YoutubeLoaded(videos: videos));
    } catch (e) {
      emit(YoutubeError(e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchVideosEvent event,
    Emitter<YoutubeState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;
    emit(const YoutubeLoading());
    try {
      final videos = await searchVideos(event.query);
      emit(YoutubeLoaded(
        videos: videos,
        isSearchResult: true,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(YoutubeError(e.toString()));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<YoutubeState> emit,
  ) async {
    emit(const YoutubeLoading());
    try {
      final videos = await getTrendingVideos();
      emit(YoutubeLoaded(videos: videos));
    } catch (e) {
      emit(YoutubeError(e.toString()));
    }
  }

  Future<void> _onLoadVideoDetails(
    LoadVideoDetails event,
    Emitter<YoutubeState> emit,
  ) async {
    emit(const VideoDetailLoading());
    try {
      final results = await Future.wait([
        getVideoDetails(event.videoId),
        getChannelDetails(event.channelId),
      ]);
      emit(VideoDetailLoaded(
        video: results[0] as dynamic,
        channel: results[1] as dynamic,
      ));
    } catch (e) {
      emit(YoutubeError(e.toString()));
    }
  }
}
