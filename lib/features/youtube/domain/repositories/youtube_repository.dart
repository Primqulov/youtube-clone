import '../../../../core/utils/result.dart';
import '../entities/channel.dart';
import '../entities/comment.dart';
import '../entities/paginated_videos.dart';
import '../entities/video.dart';

abstract class YoutubeRepository {
  Future<Result<PaginatedVideos>> getTrendingVideos({String? pageToken});
  Future<Result<PaginatedVideos>> searchVideos(
    String query, {
    String? pageToken,
  });
  Future<Result<Video>> getVideoDetails(String videoId);
  Future<Result<Channel>> getChannelDetails(String channelId);
  Future<Result<PaginatedVideos>> getChannelVideos(
    String channelId, {
    String? pageToken,
  });
  Future<Result<PaginatedComments>> getVideoComments(
    String videoId, {
    String? pageToken,
  });
  Future<Result<PaginatedVideos>> getShortsFeed({
    required String query,
    String? pageToken,
  });
}
