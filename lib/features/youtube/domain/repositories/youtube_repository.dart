import '../entities/video.dart';
import '../entities/channel.dart';

abstract class YoutubeRepository {
  Future<List<Video>> getTrendingVideos({String? pageToken});
  Future<List<Video>> searchVideos(String query, {String? pageToken});
  Future<Video> getVideoDetails(String videoId);
  Future<Channel> getChannelDetails(String channelId);
}
