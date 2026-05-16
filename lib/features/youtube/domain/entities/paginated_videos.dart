import 'package:equatable/equatable.dart';

import 'video.dart';

class PaginatedVideos extends Equatable {
  final List<Video> videos;
  final String? nextPageToken;

  const PaginatedVideos({required this.videos, this.nextPageToken});

  bool get hasMore => nextPageToken != null && nextPageToken!.isNotEmpty;

  @override
  List<Object?> get props => [videos, nextPageToken];
}
