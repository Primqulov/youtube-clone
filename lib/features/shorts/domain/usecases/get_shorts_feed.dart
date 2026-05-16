import '../../../../core/utils/result.dart';
import '../../../youtube/domain/entities/paginated_videos.dart';
import '../../../youtube/domain/repositories/youtube_repository.dart';

class GetShortsFeed {
  final YoutubeRepository repository;

  GetShortsFeed(this.repository);

  Future<Result<PaginatedVideos>> call({
    required String query,
    String? pageToken,
  }) => repository.getShortsFeed(query: query, pageToken: pageToken);
}
