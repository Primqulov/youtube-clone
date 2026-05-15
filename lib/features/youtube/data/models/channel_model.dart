import '../../domain/entities/channel.dart';

class ChannelModel extends Channel {
  const ChannelModel({
    required super.id,
    required super.title,
    required super.description,
    required super.thumbnailUrl,
    super.subscriberCount,
    super.videoCount,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final statistics = json['statistics'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};

    String thumbnailUrl = '';
    if (thumbnails.containsKey('default')) {
      thumbnailUrl = thumbnails['default']['url'] ?? '';
    }

    return ChannelModel(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: thumbnailUrl,
      subscriberCount: statistics['subscriberCount'] as String? ?? '0',
      videoCount: statistics['videoCount'] as String? ?? '0',
    );
  }
}
