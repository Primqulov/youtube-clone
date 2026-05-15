import 'package:equatable/equatable.dart';

class Video extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelId;
  final String channelTitle;
  final DateTime publishedAt;
  final String viewCount;
  final String likeCount;
  final String duration;
  final String channelAvatarUrl;

  const Video({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelId,
    required this.channelTitle,
    required this.publishedAt,
    this.viewCount = '0',
    this.likeCount = '0',
    this.duration = '',
    this.channelAvatarUrl = '',
  });

  @override
  List<Object?> get props => [id, title, channelId];
}
