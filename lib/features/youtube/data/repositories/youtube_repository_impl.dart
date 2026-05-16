import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/paginated_videos.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/youtube_repository.dart';
import '../datasources/youtube_remote_datasource.dart';

class YoutubeRepositoryImpl implements YoutubeRepository {
  final YoutubeRemoteDatasource remoteDatasource;

  YoutubeRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Result<PaginatedVideos>> getTrendingVideos({String? pageToken}) {
    return _guard(
      () => remoteDatasource.getTrendingVideos(pageToken: pageToken),
    );
  }

  @override
  Future<Result<PaginatedVideos>> searchVideos(
    String query, {
    String? pageToken,
  }) {
    return _guard(
      () => remoteDatasource.searchVideos(query, pageToken: pageToken),
    );
  }

  @override
  Future<Result<Video>> getVideoDetails(String videoId) {
    return _guard(() async {
      final video = await remoteDatasource.getVideoDetails(videoId);
      if (video.channelId.isEmpty) return video;
      final avatars = await remoteDatasource.getChannelAvatars([
        video.channelId,
      ]);
      final url = avatars[video.channelId];
      if (url == null || url.isEmpty) return video;
      return video.copyWith(channelAvatarUrl: url);
    });
  }

  @override
  Future<Result<Channel>> getChannelDetails(String channelId) {
    return _guard(() => remoteDatasource.getChannelDetails(channelId));
  }

  @override
  Future<Result<PaginatedVideos>> getChannelVideos(
    String channelId, {
    String? pageToken,
  }) {
    return _guard(
      () => remoteDatasource.getChannelVideos(channelId, pageToken: pageToken),
    );
  }

  @override
  Future<Result<PaginatedComments>> getVideoComments(
    String videoId, {
    String? pageToken,
  }) {
    return _guard(
      () => remoteDatasource.getVideoComments(videoId, pageToken: pageToken),
    );
  }

  @override
  Future<Result<PaginatedVideos>> getShortsFeed({
    required String query,
    String? pageToken,
  }) {
    return _guard(
      () => remoteDatasource.getShortsFeed(
        query: query,
        pageToken: pageToken,
      ),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Success(value);
    } catch (e) {
      return Failed(Failure.fromException(e));
    }
  }
}
