import '../../../../core/utils/thumbnail_picker.dart';
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
    final snippet = json['snippet'] as Map<String, dynamic>? ?? const {};
    final statistics =
        json['statistics'] as Map<String, dynamic>? ?? const {};

    return ChannelModel(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: pickBestThumbnailUrl(
        snippet['thumbnails'] as Map<String, dynamic>?,
        preference: const ['high', 'medium', 'default'],
      ),
      subscriberCount: statistics['subscriberCount'] as String? ?? '0',
      videoCount: statistics['videoCount'] as String? ?? '0',
    );
  }
}
