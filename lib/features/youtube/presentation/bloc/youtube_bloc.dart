import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/home_video_cache.dart';
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

  final HomeVideoCache _cache;

  YoutubeBloc({
    required this.getTrendingVideos,
    required this.searchVideos,
    required this.networkInfo,
    HomeVideoCache? cache,
  })  : _cache = cache ?? HomeVideoCache(),
        super(const YoutubeInitial()) {
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

    // Cache dan ma'lumotlarni tekshirish (query=null = home)
    if (event.forceRefresh) {
      _cache.remove(null);
    }

    final cachedVideos = _cache.getVideos(null);
    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      if (_cache.isFresh(null) && !event.forceRefresh) {
        emit(
          YoutubeLoaded(
            videos: cachedVideos,
            activeQuery: _cache.lastQuery,
            isSearchResult: false,
          ),
        );
        return;
      } else {
        // Stale cache yoki forceRefresh — show cached first then refresh
        emit(
          YoutubeLoaded(
            videos: cachedVideos,
            activeQuery: _cache.lastQuery,
            isSearchResult: false,
          ),
        );
      }
    } else {
      emit(const YoutubeLoading());
    }

    // Yangi ma'lumotlarni yuklash
    final topic = _homeTopics[_random.nextInt(_homeTopics.length)];
    final searchResult = await searchVideos(topic);

    if (searchResult is Success<PaginatedVideos> &&
        searchResult.data.videos.isNotEmpty) {
      _cache.save(searchResult.data.videos, query: topic);
      _cache.save(searchResult.data.videos, query: null);
      emit(_toLoadedState(searchResult.data, activeQuery: topic));
      return;
    }

    final trendingResult = await getTrendingVideos();
    switch (trendingResult) {
      case Success(:final data):
        _cache.save(data.videos, query: null);
        emit(_toLoadedState(data, activeQuery: null));
      case Failed(:final failure):
        if (!_cache.hasData) {
          emit(_failureToState(failure));
        }
      // Agar cache bo'lsa, error ni ko'rsatmaymiz, cached ma'lumot qoladi
    }
  }

  Future<void> _onSearch(
    SearchVideosEvent event,
    Emitter<YoutubeState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;
    _lastEvent = event;

    // Cache dan tekshirish — har bir kategoriya alohida cache da saqlanadi
    final cachedVideos = _cache.getVideos(event.query);
    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      if (_cache.isFresh(event.query)) {
        emit(
          YoutubeLoaded(
            videos: cachedVideos,
            activeQuery: event.query,
            isSearchResult: true,
            searchQuery: event.query,
          ),
        );
        return;
      } else {
        // Stale cache — show cached first then refresh
        emit(
          YoutubeLoaded(
            videos: cachedVideos,
            activeQuery: event.query,
            isSearchResult: true,
            searchQuery: event.query,
          ),
        );
      }
    } else {
      emit(const YoutubeLoading());
    }

    final result = await searchVideos(event.query);
    switch (result) {
      case Success(:final data):
        _cache.save(data.videos, query: event.query);
        emit(
          _toLoadedState(
            data,
            activeQuery: event.query,
            isSearchResult: true,
            searchQuery: event.query,
          ),
        );
      case Failed(:final failure):
        if (_cache.getVideos(event.query) == null) {
          emit(_failureToState(failure));
        }
      // Agar cache bo'lsa, error ni ko'rsatmaymiz
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
