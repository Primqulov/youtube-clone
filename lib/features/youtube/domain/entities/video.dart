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

  Video copyWith({
    String? viewCount,
    String? likeCount,
    String? duration,
    String? channelAvatarUrl,
    String? thumbnailUrl,
  }) {
    return Video(
      id: id,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      channelId: channelId,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      duration: duration ?? this.duration,
      channelAvatarUrl: channelAvatarUrl ?? this.channelAvatarUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    channelId,
    viewCount,
    duration,
    thumbnailUrl,
    channelAvatarUrl,
  ];
}
