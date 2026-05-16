import 'package:equatable/equatable.dart';

import '../../domain/entities/video.dart';

abstract class YoutubeState extends Equatable {
  const YoutubeState();

  @override
  List<Object?> get props => [];
}

class YoutubeInitial extends YoutubeState {
  const YoutubeInitial();
}

class YoutubeLoading extends YoutubeState {
  const YoutubeLoading();
}

class YoutubeLoaded extends YoutubeState {
  final List<Video> videos;
  final bool isSearchResult;
  final String searchQuery;
  final String? activeQuery;
  final String? nextPageToken;
  final bool isLoadingMore;

  const YoutubeLoaded({
    required this.videos,
    this.isSearchResult = false,
    this.searchQuery = '',
    this.activeQuery,
    this.nextPageToken,
    this.isLoadingMore = false,
  });

  bool get hasReachedEnd =>
      nextPageToken == null || nextPageToken!.isEmpty;

  YoutubeLoaded appendPage({
    required List<Video> newVideos,
    required String? nextPageToken,
  }) {
    return YoutubeLoaded(
      videos: [...videos, ...newVideos],
      isSearchResult: isSearchResult,
      searchQuery: searchQuery,
      activeQuery: activeQuery,
      nextPageToken: nextPageToken,
      isLoadingMore: false,
    );
  }

  YoutubeLoaded withLoadingMore(bool loading) {
    return YoutubeLoaded(
      videos: videos,
      isSearchResult: isSearchResult,
      searchQuery: searchQuery,
      activeQuery: activeQuery,
      nextPageToken: nextPageToken,
      isLoadingMore: loading,
    );
  }

  @override
  List<Object?> get props => [
    videos,
    isSearchResult,
    searchQuery,
    activeQuery,
    nextPageToken,
    isLoadingMore,
  ];
}

class YoutubeError extends YoutubeState {
  final String message;
  final bool isNetworkError;
  const YoutubeError(this.message, {this.isNetworkError = false});

  @override
  List<Object?> get props => [message, isNetworkError];
}
