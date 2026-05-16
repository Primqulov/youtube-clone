import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../youtube/domain/entities/video.dart';
import '../../domain/usecases/get_shorts_feed.dart';

class ShortsState extends Equatable {
  final List<Video> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final String? nextPageToken;
  final String? errorMessage;
  final String? activeQuery;

  const ShortsState({
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.nextPageToken,
    this.errorMessage,
    this.activeQuery,
  });

  bool get hasReachedEnd =>
      nextPageToken == null || nextPageToken!.isEmpty;

  ShortsState _next({
    List<Video>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    String? nextPageToken,
    String? errorMessage,
    String? activeQuery,
  }) {
    return ShortsState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      errorMessage: errorMessage,
      activeQuery: activeQuery ?? this.activeQuery,
    );
  }

  @override
  List<Object?> get props => [
    videos,
    isLoading,
    isLoadingMore,
    nextPageToken,
    errorMessage,
    activeQuery,
  ];
}

class ShortsCubit extends Cubit<ShortsState> {
  static const List<String> _topics = [
    '#shorts',
    'shorts viral',
    'shorts funny',
    'shorts trending',
    'shorts music',
    'shorts dance',
    'shorts comedy',
    'shorts asmr',
    'shorts cooking',
    'shorts gaming',
  ];

  final GetShortsFeed getShortsFeed;
  final Random _random = Random();

  ShortsCubit({required this.getShortsFeed}) : super(const ShortsState());

  Future<void> load() async {
    emit(state._next(isLoading: true));
    final query = _topics[_random.nextInt(_topics.length)];
    final result = await getShortsFeed(query: query);
    switch (result) {
      case Success(:final data):
        emit(
          state._next(
            videos: _uniqueShuffled(data.videos),
            nextPageToken: data.nextPageToken,
            isLoading: false,
            activeQuery: query,
          ),
        );
      case Failed(:final failure):
        emit(
          state._next(
            isLoading: false,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;
    final query = state.activeQuery;
    if (query == null) return;

    final hasToken = !state.hasReachedEnd;
    final fetchQuery = hasToken
        ? query
        : _topics[_random.nextInt(_topics.length)];

    emit(state._next(isLoadingMore: true));

    final result = await getShortsFeed(
      query: fetchQuery,
      pageToken: hasToken ? state.nextPageToken : null,
    );
    switch (result) {
      case Success(:final data):
        final existingIds = state.videos.map((v) => v.id).toSet();
        final fresh = data.videos
            .where((v) => v.id.isNotEmpty && existingIds.add(v.id))
            .toList();
        emit(
          state._next(
            videos: [...state.videos, ...fresh],
            nextPageToken: data.nextPageToken,
            isLoadingMore: false,
            activeQuery: fetchQuery,
          ),
        );
      case Failed():
        emit(state._next(isLoadingMore: false));
    }
  }

  List<Video> _uniqueShuffled(List<Video> items) {
    final seen = <String>{};
    final unique = <Video>[];
    for (final v in items) {
      if (v.id.isEmpty || !seen.add(v.id)) continue;
      unique.add(v);
    }
    unique.shuffle(_random);
    return unique;
  }
}
