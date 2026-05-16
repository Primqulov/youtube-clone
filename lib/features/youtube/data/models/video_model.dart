import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/thumbnail_picker.dart';
import '../../domain/entities/video.dart';

class VideoModel extends Video {
  const VideoModel({
    required super.id,
    required super.title,
    required super.description,
    required super.thumbnailUrl,
    required super.channelId,
    required super.channelTitle,
    required super.publishedAt,
    super.viewCount,
    super.likeCount,
    super.duration,
    super.channelAvatarUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? const {};
    final statistics =
        json['statistics'] as Map<String, dynamic>? ?? const {};
    final contentDetails =
        json['contentDetails'] as Map<String, dynamic>? ?? const {};

    return VideoModel(
      id: _extractId(json['id']),
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: pickBestThumbnailUrl(
        snippet['thumbnails'] as Map<String, dynamic>?,
      ),
      channelId: snippet['channelId'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ??
          DateTime.now(),
      viewCount: statistics['viewCount'] as String? ?? '0',
      likeCount: statistics['likeCount'] as String? ?? '0',
      duration: Formatters.isoDuration(
        contentDetails['duration'] as String? ?? '',
      ),
    );
  }

  static String _extractId(dynamic id) {
    if (id is Map<String, dynamic>) return id['videoId'] as String? ?? '';
    return id as String? ?? '';
  }
}
