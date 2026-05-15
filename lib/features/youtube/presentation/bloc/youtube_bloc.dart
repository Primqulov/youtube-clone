import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/get_details.dart';
import '../../domain/usecases/get_trending_videos.dart';
import '../../domain/usecases/search_videos.dart';
import 'youtube_event.dart';
import 'youtube_state.dart';

class YoutubeBloc extends Bloc<YoutubeEvent, YoutubeState> {
  static const List<String> _homeTopics = [
    'uzbek music',
    'world news',
    'football highlights',
    'technology review',
    'travel vlog',
    'cooking recipes',
    'science documentary',
    'gaming highlights',
    'education tutorials',
    'comedy videos',
    'fitness workout',
    'cars review',
  ];

  final GetTrendingVideos getTrendingVideos;
  final SearchVideos searchVideos;
  final GetVideoDetails getVideoDetails;
  final GetChannelDetails getChannelDetails;
  final NetworkInfo networkInfo;
  final Random _random = Random();

  StreamSubscription? _connectivitySubscription;
  YoutubeEvent? _lastEvent;

  YoutubeBloc({
    required this.getTrendingVideos,
    required this.searchVideos,
    required this.getVideoDetails,
    required this.getChannelDetails,
    required this.networkInfo,
  }) : super(const YoutubeInitial()) {
    on<LoadTrendingVideos>(_onLoadTrending);
    on<SearchVideosEvent>(_onSearch);
    on<ClearSearch>(_onClearSearch);
    on<LoadVideoDetails>(_onLoadVideoDetails);

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none) &&
          state is YoutubeError &&
          _lastEvent != null) {
        add(_lastEvent!);
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadTrending(
    LoadTrendingVideos event,
    Emitter<YoutubeState> emit,
  ) async {
    _lastEvent = event;
    emit(const YoutubeLoading());
    try {
      final videos = await _loadRandomHomeVideos();
      emit(YoutubeLoaded(videos: videos));
    } catch (e) {
      emit(YoutubeError(_friendlyError(e)));
    }
  }

  Future<void> _onSearch(
    SearchVideosEvent event,
    Emitter<YoutubeState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;
    _lastEvent = event;
    emit(const YoutubeLoading());
    try {
      final videos = await searchVideos(event.query);
      emit(
        YoutubeLoaded(
          videos: _uniqueRandomized(videos),
          isSearchResult: true,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      emit(YoutubeError(_friendlyError(e)));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<YoutubeState> emit,
  ) async {
    _lastEvent = const LoadTrendingVideos();
    emit(const YoutubeLoading());
    try {
      final videos = await _loadRandomHomeVideos();
      emit(YoutubeLoaded(videos: videos));
    } catch (e) {
      emit(YoutubeError(_friendlyError(e)));
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
      emit(
        VideoDetailLoaded(
          video: results[0] as dynamic,
          channel: results[1] as dynamic,
        ),
      );
    } catch (e) {
      emit(YoutubeError(_friendlyError(e)));
    }
  }

  Future<List<Video>> _loadRandomHomeVideos() async {
    final topic = _homeTopics[_random.nextInt(_homeTopics.length)];

    try {
      final videos = await searchVideos(topic);
      if (videos.isNotEmpty) return _uniqueRandomized(videos);
    } catch (_) {
      // If search fails, fall back to the YouTube trending endpoint below.
    }

    final videos = await getTrendingVideos();
    return _uniqueRandomized(videos);
  }

  List<Video> _uniqueRandomized(List<Video> items) {
    final seenVideoIds = <String>{};
    final uniqueItems = <Video>[];

    for (final video in items) {
      if (video.id.isEmpty || !seenVideoIds.add(video.id)) continue;
      uniqueItems.add(video);
    }

    uniqueItems.shuffle(_random);
    return uniqueItems;
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') || message.contains('Internet')) {
      return 'Internet ulanishi mavjud emas';
    }
    return message;
  }
}
