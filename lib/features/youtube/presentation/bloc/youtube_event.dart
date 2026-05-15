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

class LoadVideoDetails extends YoutubeEvent {
  final String videoId;
  final String channelId;
  const LoadVideoDetails({required this.videoId, required this.channelId});

  @override
  List<Object?> get props => [videoId, channelId];
}
