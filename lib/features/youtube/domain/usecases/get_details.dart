import '../entities/video.dart';
import '../entities/channel.dart';
import '../repositories/youtube_repository.dart';

class GetVideoDetails {
  final YoutubeRepository repository;

  GetVideoDetails(this.repository);

  Future<Video> call(String videoId) {
    return repository.getVideoDetails(videoId);
  }
}

class GetChannelDetails {
  final YoutubeRepository repository;

  GetChannelDetails(this.repository);

  Future<Channel> call(String channelId) {
    return repository.getChannelDetails(channelId);
  }
}
