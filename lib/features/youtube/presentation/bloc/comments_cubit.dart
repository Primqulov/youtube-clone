import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/usecases/get_comments.dart';

class CommentsState extends Equatable {
  final String videoId;
  final List<Comment> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isDisabled;
  final String? nextPageToken;
  final String? errorMessage;

  const CommentsState({
    required this.videoId,
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isDisabled = false,
    this.nextPageToken,
    this.errorMessage,
  });

  bool get hasReachedEnd =>
      nextPageToken == null || nextPageToken!.isEmpty;

  CommentsState _next({
    List<Comment>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isDisabled,
    String? nextPageToken,
    String? errorMessage,
  }) {
    return CommentsState(
      videoId: videoId,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isDisabled: isDisabled ?? this.isDisabled,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    videoId,
    comments,
    isLoading,
    isLoadingMore,
    isDisabled,
    nextPageToken,
    errorMessage,
  ];
}

class CommentsCubit extends Cubit<CommentsState> {
  final GetVideoComments getVideoComments;

  CommentsCubit({required String videoId, required this.getVideoComments})
      : super(CommentsState(videoId: videoId));

  Future<void> load() async {
    emit(state._next(isLoading: true));
    final result = await getVideoComments(state.videoId);
    switch (result) {
      case Success(:final data):
        emit(
          state._next(
            comments: data.comments,
            nextPageToken: data.nextPageToken,
            isLoading: false,
          ),
        );
      case Failed(:final failure):
        final disabled = failure.message.toLowerCase().contains('disabled') ||
            failure.message.contains('403');
        emit(
          state._next(
            isLoading: false,
            isDisabled: disabled,
            errorMessage: disabled ? null : failure.message,
          ),
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedEnd) {
      return;
    }
    emit(state._next(isLoadingMore: true));
    final result = await getVideoComments(
      state.videoId,
      pageToken: state.nextPageToken,
    );
    switch (result) {
      case Success(:final data):
        final existingIds = state.comments.map((c) => c.id).toSet();
        final fresh = data.comments
            .where((c) => c.id.isNotEmpty && existingIds.add(c.id))
            .toList();
        emit(
          state._next(
            comments: [...state.comments, ...fresh],
            nextPageToken: data.nextPageToken,
            isLoadingMore: false,
          ),
        );
      case Failed():
        emit(state._next(isLoadingMore: false));
    }
  }
}
