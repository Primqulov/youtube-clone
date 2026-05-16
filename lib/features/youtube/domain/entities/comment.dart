import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String authorName;
  final String authorAvatarUrl;
  final String authorChannelId;
  final String text;
  final int likeCount;
  final int replyCount;
  final DateTime publishedAt;

  const Comment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.publishedAt,
    this.authorAvatarUrl = '',
    this.authorChannelId = '',
    this.likeCount = 0,
    this.replyCount = 0,
  });

  @override
  List<Object?> get props => [id, text, likeCount, replyCount];
}

class PaginatedComments extends Equatable {
  final List<Comment> comments;
  final String? nextPageToken;

  const PaginatedComments({required this.comments, this.nextPageToken});

  bool get hasMore => nextPageToken != null && nextPageToken!.isNotEmpty;

  @override
  List<Object?> get props => [comments, nextPageToken];
}
