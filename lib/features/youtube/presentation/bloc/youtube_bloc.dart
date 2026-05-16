import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/paginated_videos.dart';
import '../../domain/entities/video.dart';
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
  final NetworkInfo networkInfo;
  final Random _random = Random();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  YoutubeEvent? _lastEvent;

  YoutubeBloc({
    required this.getTrendingVideos,
    required this.searchVideos,
    required this.networkInfo,
  }) : super(const YoutubeInitial()) {
    on<LoadTrendingVideos>(_onLoadTrending);
    on<SearchVideosEvent>(_onSearch);
    on<ClearSearch>(_onClearSearch);
    on<LoadMoreVideos>(_onLoadMore);

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      results,
    ) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && state is YoutubeError && _lastEvent != null) {
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

    final topic = _homeTopics[_random.nextInt(_homeTopics.length)];
    final searchResult = await searchVideos(topic);

    if (searchResult is Success<PaginatedVideos> &&
        searchResult.data.videos.isNotEmpty) {
      emit(_toLoadedState(searchResult.data, activeQuery: topic));
      return;
    }

    final trendingResult = await getTrendingVideos();
    switch (trendingResult) {
      case Success(:final data):
        emit(_toLoadedState(data, activeQuery: null));
      case Failed(:final failure):
        emit(_failureToState(failure));
    }
  }

  Future<void> _onSearch(
    SearchVideosEvent event,
    Emitter<YoutubeState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;
    _lastEvent = event;
    emit(const YoutubeLoading());

    final result = await searchVideos(event.query);
    switch (result) {
      case Success(:final data):
        emit(
          _toLoadedState(
            data,
            activeQuery: event.query,
            isSearchResult: true,
            searchQuery: event.query,
          ),
        );
      case Failed(:final failure):
        emit(_failureToState(failure));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<YoutubeState> emit,
  ) async {
    _lastEvent = const LoadTrendingVideos();
    add(const LoadTrendingVideos());
  }

  Future<void> _onLoadMore(
    LoadMoreVideos event,
    Emitter<YoutubeState> emit,
  ) async {
    final current = state;
    if (current is! YoutubeLoaded) return;
    if (current.isLoadingMore || current.hasReachedEnd) return;

    emit(current.withLoadingMore(true));

    final result = current.activeQuery != null
        ? await searchVideos(
            current.activeQuery!,
            pageToken: current.nextPageToken,
          )
        : await getTrendingVideos(pageToken: current.nextPageToken);

    switch (result) {
      case Success(:final data):
        final dedupedNew = _dedupAgainst(data.videos, current.videos);
        emit(
          current.appendPage(
            newVideos: dedupedNew,
            nextPageToken: data.nextPageToken,
          ),
        );
      case Failed():
        emit(current.withLoadingMore(false));
    }
  }

  YoutubeLoaded _toLoadedState(
    PaginatedVideos page, {
    required String? activeQuery,
    bool isSearchResult = false,
    String searchQuery = '',
  }) {
    return YoutubeLoaded(
      videos: _uniqueRandomized(page.videos),
      isSearchResult: isSearchResult,
      searchQuery: searchQuery,
      activeQuery: activeQuery,
      nextPageToken: page.nextPageToken,
    );
  }

  YoutubeState _failureToState(Failure failure) {
    return YoutubeError(
      failure.message,
      isNetworkError: failure is NetworkFailure,
    );
  }

  List<Video> _uniqueRandomized(List<Video> items) {
    final seen = <String>{};
    final unique = <Video>[];
    for (final video in items) {
      if (video.id.isEmpty || !seen.add(video.id)) continue;
      unique.add(video);
    }
    unique.shuffle(_random);
    return unique;
  }

  List<Video> _dedupAgainst(List<Video> newItems, List<Video> existing) {
    final seen = existing.map((v) => v.id).toSet();
    return newItems
        .where((v) => v.id.isNotEmpty && seen.add(v.id))
        .toList();
  }
}
