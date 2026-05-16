import 'package:equatable/equatable.dart';

abstract class YoutubeEvent extends Equatable {
  const YoutubeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrendingVideos extends YoutubeEvent {
  const LoadTrendingVideos();
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
