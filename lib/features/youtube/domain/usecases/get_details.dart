import '../../../../core/utils/result.dart';
import '../entities/channel.dart';
import '../entities/paginated_videos.dart';
import '../entities/video.dart';
import '../repositories/youtube_repository.dart';

class GetVideoDetails {
  final YoutubeRepository repository;

  GetVideoDetails(this.repository);

  Future<Result<Video>> call(String videoId) =>
      repository.getVideoDetails(videoId);
}

class GetChannelDetails {
  final YoutubeRepository repository;

  GetChannelDetails(this.repository);

  Future<Result<Channel>> call(String channelId) =>
      repository.getChannelDetails(channelId);
}

class GetChannelVideos {
  final YoutubeRepository repository;

  GetChannelVideos(this.repository);

  Future<Result<PaginatedVideos>> call(
    String channelId, {
    String? pageToken,
  }) => repository.getChannelVideos(channelId, pageToken: pageToken);
}
