import 'package:equatable/equatable.dart';

abstract class YoutubeEvent extends Equatable {
  const YoutubeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrendingVideos extends YoutubeEvent {
  final bool forceRefresh;
  const LoadTrendingVideos({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SearchVideosEvent extends YoutubeEvent {
  final String query;
  const SearchVideosEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends YoutubeEvent {
  const ClearSearch();
}

class LoadMoreVideos extends YoutubeEvent {
  const LoadMoreVideos();
}
