import '../entities/video.dart';
import '../repositories/youtube_repository.dart';

class GetTrendingVideos {
  final YoutubeRepository repository;

  GetTrendingVideos(this.repository);

  Future<List<Video>> call({String? pageToken}) {
    return repository.getTrendingVideos(pageToken: pageToken);
  }
}
