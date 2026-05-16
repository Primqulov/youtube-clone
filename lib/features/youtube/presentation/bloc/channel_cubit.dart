import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/get_details.dart';

class ChannelPageState extends Equatable {
  final String channelId;
  final Channel? channel;
  final List<Video> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final String? nextPageToken;
  final String? errorMessage;

  const ChannelPageState({
    required this.channelId,
    this.channel,
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.nextPageToken,
    this.errorMessage,
  });

  bool get hasReachedEnd =>
      nextPageToken == null || nextPageToken!.isEmpty;

  ChannelPageState _next({
    Channel? channel,
    List<Video>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    String? nextPageToken,
    String? errorMessage,
  }) {
    return ChannelPageState(
      channelId: channelId,
      channel: channel ?? this.channel,
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    channelId,
    channel,
    videos,
    isLoading,
    isLoadingMore,
    nextPageToken,
    errorMessage,
  ];
}

class ChannelCubit extends Cubit<ChannelPageState> {
  final GetChannelDetails getChannelDetails;
  final GetChannelVideos getChannelVideos;

  ChannelCubit({
    required String channelId,
    Channel? seedChannel,
    required this.getChannelDetails,
    required this.getChannelVideos,
  }) : super(
          ChannelPageState(channelId: channelId, channel: seedChannel),
        );

  Future<void> load() async {
    emit(state._next(isLoading: true));

    final (detailsResult, videosResult) = await (
      getChannelDetails(state.channelId),
      getChannelVideos(state.channelId),
    ).wait;

    final channel = switch (detailsResult) {
      Success(:final data) => data,
      Failed() => state.channel,
    };
    final videos = switch (videosResult) {
      Success(:final data) => data.videos,
      Failed() => state.videos,
    };
    final nextPageToken = switch (videosResult) {
      Success(:final data) => data.nextPageToken,
      Failed() => state.nextPageToken,
    };
    final error = switch ((detailsResult, videosResult)) {
      (Failed(:final failure), _) => failure.message,
      (_, Failed(:final failure)) => failure.message,
      _ => null,
    };

    emit(
      state._next(
        channel: channel,
        videos: videos,
        nextPageToken: nextPageToken,
        isLoading: false,
        errorMessage: error,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isLoading) {
      return;
    }
    emit(state._next(isLoadingMore: true));

    final result = await getChannelVideos(
      state.channelId,
      pageToken: state.nextPageToken,
    );

    switch (result) {
      case Success(:final data):
        final existingIds = state.videos.map((v) => v.id).toSet();
        final fresh = data.videos
            .where((v) => v.id.isNotEmpty && existingIds.add(v.id))
            .toList();
        emit(
          state._next(
            videos: [...state.videos, ...fresh],
            nextPageToken: data.nextPageToken,
            isLoadingMore: false,
          ),
        );
      case Failed():
        emit(state._next(isLoadingMore: false));
    }
  }
}
