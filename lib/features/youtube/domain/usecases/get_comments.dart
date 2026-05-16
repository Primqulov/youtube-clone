import '../../../../core/utils/result.dart';
import '../entities/comment.dart';
import '../repositories/youtube_repository.dart';

class GetVideoComments {
  final YoutubeRepository repository;

  GetVideoComments(this.repository);

  Future<Result<PaginatedComments>> call(
    String videoId, {
    String? pageToken,
  }) => repository.getVideoComments(videoId, pageToken: pageToken);
}
