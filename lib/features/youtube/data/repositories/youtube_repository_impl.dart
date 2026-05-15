import '../../domain/entities/video.dart';
import '../../domain/entities/channel.dart';
import '../../domain/repositories/youtube_repository.dart';
import '../datasources/youtube_remote_datasource.dart';

class YoutubeRepositoryImpl implements YoutubeRepository {
  final YoutubeRemoteDatasource remoteDatasource;

  YoutubeRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Video>> getTrendingVideos({String? pageToken}) async {
    return await remoteDatasource.getTrendingVideos(pageToken: pageToken);
  }

  @override
  Future<List<Video>> searchVideos(String query, {String? pageToken}) async {
    return await remoteDatasource.searchVideos(query, pageToken: pageToken);
  }

  @override
  Future<Video> getVideoDetails(String videoId) async {
    return await remoteDatasource.getVideoDetails(videoId);
  }

  @override
  Future<Channel> getChannelDetails(String channelId) async {
    return await remoteDatasource.getChannelDetails(channelId);
  }
}
