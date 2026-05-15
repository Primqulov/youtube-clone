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

  factory VideoModel.fromTrendingJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final statistics = json['statistics'] as Map<String, dynamic>? ?? {};
    final contentDetails = json['contentDetails'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};

    String thumbnailUrl = '';
    if (thumbnails.containsKey('maxres')) {
      thumbnailUrl = thumbnails['maxres']['url'] ?? '';
    } else if (thumbnails.containsKey('high')) {
      thumbnailUrl = thumbnails['high']['url'] ?? '';
    } else if (thumbnails.containsKey('medium')) {
      thumbnailUrl = thumbnails['medium']['url'] ?? '';
    } else if (thumbnails.containsKey('default')) {
      thumbnailUrl = thumbnails['default']['url'] ?? '';
    }

    return VideoModel(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: thumbnailUrl,
      channelId: snippet['channelId'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      publishedAt: DateTime.tryParse(snippet['publishedAt'] ?? '') ?? DateTime.now(),
      viewCount: statistics['viewCount'] as String? ?? '0',
      likeCount: statistics['likeCount'] as String? ?? '0',
      duration: _parseDuration(contentDetails['duration'] as String? ?? ''),
    );
  }

  factory VideoModel.fromSearchJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final idData = json['id'];
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};

    String videoId;
    if (idData is Map<String, dynamic>) {
      videoId = idData['videoId'] as String? ?? '';
    } else {
      videoId = idData as String? ?? '';
    }

    String thumbnailUrl = '';
    if (thumbnails.containsKey('high')) {
      thumbnailUrl = thumbnails['high']['url'] ?? '';
    } else if (thumbnails.containsKey('medium')) {
      thumbnailUrl = thumbnails['medium']['url'] ?? '';
    } else if (thumbnails.containsKey('default')) {
      thumbnailUrl = thumbnails['default']['url'] ?? '';
    }

    return VideoModel(
      id: videoId,
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: thumbnailUrl,
      channelId: snippet['channelId'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      publishedAt: DateTime.tryParse(snippet['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }

  static String _parseDuration(String isoDuration) {
    if (isoDuration.isEmpty) return '';

    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);

    if (match == null) return '';

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  VideoModel copyWithStats({
    String? viewCount,
    String? likeCount,
    String? duration,
    String? channelAvatarUrl,
  }) {
    return VideoModel(
      id: id,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      channelId: channelId,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      duration: duration ?? this.duration,
      channelAvatarUrl: channelAvatarUrl ?? this.channelAvatarUrl,
    );
  }
}
