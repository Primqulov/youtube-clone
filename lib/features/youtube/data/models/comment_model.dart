import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.authorName,
    required super.text,
    required super.publishedAt,
    super.authorAvatarUrl,
    super.authorChannelId,
    super.likeCount,
    super.replyCount,
  });

  factory CommentModel.fromThreadJson(Map<String, dynamic> json) {
    final threadSnippet = json['snippet'] as Map<String, dynamic>? ?? const {};
    final top = threadSnippet['topLevelComment'] as Map<String, dynamic>? ??
        const {};
    final commentSnippet =
        top['snippet'] as Map<String, dynamic>? ?? const {};
    final authorChannel =
        commentSnippet['authorChannelId'] as Map<String, dynamic>?;

    return CommentModel(
      id: top['id'] as String? ?? '',
      authorName: commentSnippet['authorDisplayName'] as String? ?? '',
      authorAvatarUrl:
          commentSnippet['authorProfileImageUrl'] as String? ?? '',
      authorChannelId: authorChannel?['value'] as String? ?? '',
      text: _decodeHtml(
        (commentSnippet['textDisplay'] ??
                commentSnippet['textOriginal'] ??
                '')
            as String,
      ),
      likeCount: (commentSnippet['likeCount'] as num?)?.toInt() ?? 0,
      replyCount: (threadSnippet['totalReplyCount'] as num?)?.toInt() ?? 0,
      publishedAt:
          DateTime.tryParse(commentSnippet['publishedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String _decodeHtml(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }
}
