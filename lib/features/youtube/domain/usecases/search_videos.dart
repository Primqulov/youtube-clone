import '../entities/video.dart';
import '../repositories/youtube_repository.dart';

class SearchVideos {
  final YoutubeRepository repository;

  SearchVideos(this.repository);

  Future<List<Video>> call(String query, {String? pageToken}) {
    return repository.searchVideos(query, pageToken: pageToken);
  }
}
