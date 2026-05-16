import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/get_details.dart';

class VideoDetailState extends Equatable {
  final Video video;
  final Channel? channel;
  final bool isLoading;
  final String? errorMessage;

  const VideoDetailState({
    required this.video,
    this.channel,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [video, channel, isLoading, errorMessage];
}

class VideoDetailCubit extends Cubit<VideoDetailState> {
  final GetVideoDetails getVideoDetails;
  final GetChannelDetails getChannelDetails;

  VideoDetailCubit({
    required Video initialVideo,
    required this.getVideoDetails,
    required this.getChannelDetails,
  }) : super(VideoDetailState(video: initialVideo));

  Future<void> load() async {
    emit(VideoDetailState(video: state.video, isLoading: true));

    final (videoResult, channelResult) = await (
      getVideoDetails(state.video.id),
      getChannelDetails(state.video.channelId),
    ).wait;

    var updatedVideo = state.video;
    if (videoResult case Success(:final data)) {
      updatedVideo = updatedVideo.copyWith(
        viewCount: data.viewCount,
        likeCount: data.likeCount,
        duration: data.duration,
      );
    }
    Channel? channel;
    if (channelResult case Success(:final data)) {
      channel = data;
      updatedVideo = updatedVideo.copyWith(channelAvatarUrl: data.thumbnailUrl);
    }
    final error = switch ((videoResult, channelResult)) {
      (Failed(:final failure), _) => failure.message,
      (_, Failed(:final failure)) => failure.message,
      _ => null,
    };

    emit(
      VideoDetailState(
        video: updatedVideo,
        channel: channel,
        isLoading: false,
        errorMessage: error,
      ),
    );
  }
}
