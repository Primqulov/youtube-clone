import 'package:equatable/equatable.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/channel.dart';

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

  const YoutubeLoaded({
    required this.videos,
    this.isSearchResult = false,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [videos, isSearchResult, searchQuery];
}

class VideoDetailLoaded extends YoutubeState {
  final Video video;
  final Channel channel;

  const VideoDetailLoaded({required this.video, required this.channel});

  @override
  List<Object?> get props => [video, channel];
}

class VideoDetailLoading extends YoutubeState {
  const VideoDetailLoading();
}

class YoutubeError extends YoutubeState {
  final String message;
  const YoutubeError(this.message);

  @override
  List<Object?> get props => [message];
}
