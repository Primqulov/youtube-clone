import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/video_model.dart';
import '../models/channel_model.dart';

class YoutubeRemoteDatasource {
  final ApiClient apiClient;

  YoutubeRemoteDatasource({required this.apiClient});

  Future<List<VideoModel>> getTrendingVideos({String? pageToken}) async {
    final url = ApiConstants.trendingUrl(pageToken: pageToken);
    final data = await apiClient.get(url);
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => VideoModel.fromTrendingJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<VideoModel>> searchVideos(String query, {String? pageToken}) async {
    final url = ApiConstants.searchUrl(query, pageToken: pageToken);
    final data = await apiClient.get(url);
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => VideoModel.fromSearchJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VideoModel> getVideoDetails(String videoId) async {
    final url = ApiConstants.videoDetailsUrl(videoId);
    final data = await apiClient.get(url);
    final items = data['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      throw Exception('Video topilmadi');
    }
    return VideoModel.fromTrendingJson(items.first as Map<String, dynamic>);
  }

  Future<ChannelModel> getChannelDetails(String channelId) async {
    final url = ApiConstants.channelUrl(channelId);
    final data = await apiClient.get(url);
    final items = data['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      throw Exception('Kanal topilmadi');
    }
    return ChannelModel.fromJson(items.first as Map<String, dynamic>);
  }
}
