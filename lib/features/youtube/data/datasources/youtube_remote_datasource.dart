import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/thumbnail_picker.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/paginated_videos.dart';
import '../../domain/entities/video.dart';
import '../models/channel_model.dart';
import '../models/comment_model.dart';
import '../models/video_model.dart';

class YoutubeRemoteDatasource {
  static const int _shortsMaxSeconds = 60;
  static const int _batchSize = 50;

  final ApiClient apiClient;
  final Map<String, String> _avatarCache = {};

  YoutubeRemoteDatasource({required this.apiClient});

  Future<PaginatedVideos> getTrendingVideos({String? pageToken}) async {
    final data = await apiClient.get(
      ApiConstants.trendingUrl(pageToken: pageToken),
    );
    final page = _toPaginated(data);
    return _excludeShorts(await _withAvatars(page));
  }

  Future<PaginatedVideos> searchVideos(
    String query, {
    String? pageToken,
  }) async {
    final data = await apiClient.get(
      ApiConstants.searchUrl(query, pageToken: pageToken),
    );
    return _excludeShorts(await _enrichAndAvatarize(_toPaginated(data)));
  }

  Future<PaginatedVideos> getShortsFeed({
    required String query,
    String? pageToken,
  }) async {
    final data = await apiClient.get(
      ApiConstants.searchUrl(
        query,
        pageToken: pageToken,
        videoDuration: 'short',
      ),
    );
    return _keepOnlyShorts(await _enrichAndAvatarize(_toPaginated(data)));
  }

  Future<VideoModel> getVideoDetails(String videoId) async {
    final data = await apiClient.get(ApiConstants.videoDetailsUrl(videoId));
    final items = data['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) {
      throw const ServerException('Video topilmadi');
    }
    return VideoModel.fromJson(items.first as Map<String, dynamic>);
  }

  Future<PaginatedVideos> getChannelVideos(
    String channelId, {
    String? pageToken,
  }) async {
    final data = await apiClient.get(
      ApiConstants.channelVideosUrl(channelId, pageToken: pageToken),
    );
    return _excludeShorts(await _enrichAndAvatarize(_toPaginated(data)));
  }

  Future<PaginatedComments> getVideoComments(
    String videoId, {
    String? pageToken,
  }) async {
    final data = await apiClient.get(
      ApiConstants.commentsUrl(videoId, pageToken: pageToken),
    );
    final items = data['items'] as List<dynamic>? ?? const [];
    final comments = items
        .map((item) => CommentModel.fromThreadJson(item as Map<String, dynamic>))
        .where((c) => c.id.isNotEmpty)
        .toList();
    return PaginatedComments(
      comments: comments,
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  Future<ChannelModel> getChannelDetails(String channelId) async {
    final data = await apiClient.get(ApiConstants.channelUrl(channelId));
    final items = data['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) {
      throw const ServerException('Kanal topilmadi');
    }
    return ChannelModel.fromJson(items.first as Map<String, dynamic>);
  }

  Future<Map<String, String>> getChannelAvatars(Iterable<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet();
    if (unique.isEmpty) return const {};

    final result = <String, String>{};
    final toFetch = <String>[];
    for (final id in unique) {
      final cached = _avatarCache[id];
      if (cached != null) {
        result[id] = cached;
      } else {
        toFetch.add(id);
      }
    }
    if (toFetch.isEmpty) return result;

    final batches = await Future.wait(
      _chunk(toFetch, _batchSize).map(_fetchAvatarBatch),
    );
    for (final batch in batches) {
      batch.forEach((id, url) {
        _avatarCache[id] = url;
        result[id] = url;
      });
    }
    return result;
  }

  Future<PaginatedVideos> _enrichAndAvatarize(PaginatedVideos page) async {
    if (page.videos.isEmpty) return page;
    final videoIds = _uniqueIds(page.videos.map((v) => v.id));
    final channelIds = page.videos.map((v) => v.channelId);

    final (details, avatars) = await (
      _fetchVideoDetails(videoIds),
      getChannelAvatars(channelIds),
    ).wait;

    final merged = page.videos.map((v) {
      Video result = details[v.id] ?? v;
      final avatarUrl = avatars[result.channelId];
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        result = result.copyWith(channelAvatarUrl: avatarUrl);
      }
      return result;
    }).toList();

    return PaginatedVideos(
      videos: merged,
      nextPageToken: page.nextPageToken,
    );
  }

  Future<PaginatedVideos> _withAvatars(PaginatedVideos page) async {
    if (page.videos.isEmpty) return page;
    final avatars = await getChannelAvatars(
      page.videos.map((v) => v.channelId),
    );
    if (avatars.isEmpty) return page;
    final enriched = page.videos.map((v) {
      final url = avatars[v.channelId];
      if (url == null || url.isEmpty) return v;
      return v.copyWith(channelAvatarUrl: url);
    }).toList();
    return PaginatedVideos(
      videos: enriched,
      nextPageToken: page.nextPageToken,
    );
  }

  Future<Map<String, VideoModel>> _fetchVideoDetails(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    final batches = await Future.wait(
      _chunk(ids, _batchSize).map(_fetchDetailsBatch),
    );
    return {for (final batch in batches) ...batch};
  }

  Future<Map<String, VideoModel>> _fetchDetailsBatch(
    List<String> chunk,
  ) async {
    final data = await apiClient.get(ApiConstants.videosByIdsUrl(chunk));
    final items = data['items'] as List<dynamic>? ?? const [];
    final batch = <String, VideoModel>{};
    for (final item in items) {
      final video = VideoModel.fromJson(item as Map<String, dynamic>);
      if (video.id.isNotEmpty) batch[video.id] = video;
    }
    return batch;
  }

  Future<Map<String, String>> _fetchAvatarBatch(List<String> chunk) async {
    final data = await apiClient.get(ApiConstants.channelsByIdsUrl(chunk));
    final items = data['items'] as List<dynamic>? ?? const [];
    final batch = <String, String>{};
    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String? ?? '';
      if (id.isEmpty) continue;
      final snippet = map['snippet'] as Map<String, dynamic>? ?? const {};
      final url = pickBestThumbnailUrl(
        snippet['thumbnails'] as Map<String, dynamic>?,
        preference: const ['high', 'medium', 'default'],
      );
      if (url.isNotEmpty) batch[id] = url;
    }
    return batch;
  }

  PaginatedVideos _toPaginated(Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>? ?? const [];
    final videos = items
        .map((item) => VideoModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return PaginatedVideos(
      videos: videos,
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  PaginatedVideos _excludeShorts(PaginatedVideos page) {
    final filtered = page.videos.where((v) {
      final seconds = Formatters.durationStringToSeconds(v.duration);
      return seconds == 0 || seconds > _shortsMaxSeconds;
    }).toList();
    return PaginatedVideos(
      videos: filtered,
      nextPageToken: page.nextPageToken,
    );
  }

  PaginatedVideos _keepOnlyShorts(PaginatedVideos page) {
    final filtered = page.videos.where((v) {
      final seconds = Formatters.durationStringToSeconds(v.duration);
      return seconds > 0 && seconds <= _shortsMaxSeconds;
    }).toList();
    return PaginatedVideos(
      videos: filtered,
      nextPageToken: page.nextPageToken,
    );
  }

  static List<String> _uniqueIds(Iterable<String> ids) =>
      ids.where((id) => id.isNotEmpty).toSet().toList();

  static Iterable<List<T>> _chunk<T>(List<T> items, int size) sync* {
    for (var i = 0; i < items.length; i += size) {
      final end = i + size > items.length ? items.length : i + size;
      yield items.sublist(i, end);
    }
  }
}
