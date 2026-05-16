import '../../../../core/utils/result.dart';
import '../entities/paginated_videos.dart';
import '../repositories/youtube_repository.dart';

class GetTrendingVideos {
  final YoutubeRepository repository;

  GetTrendingVideos(this.repository);

  Future<Result<PaginatedVideos>> call({String? pageToken}) =>
      repository.getTrendingVideos(pageToken: pageToken);
}
