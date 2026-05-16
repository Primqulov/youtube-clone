import '../../../../core/utils/result.dart';
import '../entities/paginated_videos.dart';
import '../repositories/youtube_repository.dart';

class SearchVideos {
  final YoutubeRepository repository;

  SearchVideos(this.repository);

  Future<Result<PaginatedVideos>> call(String query, {String? pageToken}) =>
      repository.searchVideos(query, pageToken: pageToken);
}
