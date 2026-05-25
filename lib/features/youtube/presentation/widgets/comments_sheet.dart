import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/comment.dart';
import '../bloc/comments_cubit.dart';
import 'channel_avatar.dart';

Future<void> showCommentsSheet(
  BuildContext context, {
  required String videoId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) =>
          di.sl<CommentsCubit>(param1: videoId)..load(),
      child: const _CommentsSheet(),
    ),
  );
}

class _CommentsSheet extends StatelessWidget {
  const _CommentsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetScroll) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              _Header(),
              const Divider(height: 1, color: AppTheme.dividerColor),
              Expanded(
                child: BlocBuilder<CommentsCubit, CommentsState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }
                    if (state.isDisabled) {
                      return const _EmptyState(
                        icon: Icons.comments_disabled_outlined,
                        message: AppStrings.commentsDisabled,
                      );
                    }
                    if (state.errorMessage != null && state.comments.isEmpty) {
                      return _EmptyState(
                        icon: Icons.error_outline,
                        message: state.errorMessage!,
                      );
                    }
                    if (state.comments.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.chat_bubble_outline,
                        message: AppStrings.commentsEmpty,
                      );
                    }
                    return _CommentsList(
                      state: state,
                      scrollController: sheetScroll,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textTertiary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        children: [
          const Text(
            AppStrings.commentsTitle,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppDimensions.fontSizeXl,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<CommentsCubit, CommentsState>(
            buildWhen: (a, b) => a.comments.length != b.comments.length,
            builder: (context, state) {
              if (state.comments.isEmpty) return const SizedBox.shrink();
              return Text(
                state.comments.length.toString(),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  static const double _loadMoreThreshold = 300;

  final CommentsState state;
  final ScrollController scrollController;

  const _CommentsList({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - _loadMoreThreshold) {
          context.read<CommentsCubit>().loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.comments.length + 1,
        itemBuilder: (context, index) {
          if (index == state.comments.length) {
            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox(height: 32);
          }
          return _CommentTile(comment: state.comments[index]);
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorAvatar(comment: comment),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.timeAgo(comment.publishedAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.compactCount(comment.likeCount.toString()),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.thumb_down_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    if (comment.replyCount > 0) ...[
                      const SizedBox(width: 20),
                      Text(
                        '${comment.replyCount} ${AppStrings.commentReply}',
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: AppDimensions.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final Comment comment;
  const _AuthorAvatar({required this.comment});

  @override
  Widget build(BuildContext context) {
    if (comment.authorAvatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: comment.authorAvatarUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          placeholder: (_, _) => ChannelAvatar(
            avatarUrl: '',
            channelTitle: comment.authorName,
            size: 32,
          ),
          errorWidget: (_, _, _) => ChannelAvatar(
            avatarUrl: '',
            channelTitle: comment.authorName,
            size: 32,
          ),
        ),
      );
    }
    return ChannelAvatar(
      avatarUrl: '',
      channelTitle: comment.authorName,
      size: 32,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textTertiary, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
