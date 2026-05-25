import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/route_observer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/channel.dart';
import '../../domain/entities/video.dart';
import '../bloc/video_detail_cubit.dart';
import '../widgets/channel_avatar.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/native_video_player.dart';
import '../widgets/video_card.dart';
import 'channel_page.dart';

class VideoPlayerPage extends StatelessWidget {
  final Video video;
  final List<Video> recommendedVideos;

  const VideoPlayerPage({
    super.key,
    required this.video,
    this.recommendedVideos = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<VideoDetailCubit>(param1: video)..load(),
      child: _VideoPlayerView(
        initialVideo: video,
        recommendedVideos: recommendedVideos,
      ),
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  final Video initialVideo;
  final List<Video> recommendedVideos;

  const _VideoPlayerView({
    required this.initialVideo,
    required this.recommendedVideos,
  });

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> with RouteAware {
  late final List<Video> _recommendedVideos;
  final GlobalKey<NativeVideoPlayerState> _playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _recommendedVideos = _buildRecommendations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    // Boshqa sahifaga o'tganda videoni pauza qilish
    _playerKey.currentState?.pause();
  }

  @override
  void didPopNext() {
    // Qaytib kelganda videoni davom ettirish
    _playerKey.currentState?.play();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  List<Video> _buildRecommendations() {
    final seen = <String>{widget.initialVideo.id};
    final videos = <Video>[];
    for (final video in widget.recommendedVideos) {
      if (video.id.isEmpty || !seen.add(video.id)) continue;
      videos.add(video);
    }
    videos.shuffle(Random());
    return videos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            NativeVideoPlayer(
              key: _playerKey,
              videoId: widget.initialVideo.id,
              autoPlay: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: BlocBuilder<VideoDetailCubit, VideoDetailState>(
                builder: (context, state) {
                  final video = state.video;
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _VideoMeta(
                          video: video,
                          channel: state.channel,
                          isLoading: state.isLoading,
                        ),
                      ),
                      if (_recommendedVideos.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: VideoCard(
                                video: _recommendedVideos[index],
                                recommendedVideos:
                                    widget.recommendedVideos,
                              ),
                            ),
                            childCount: _recommendedVideos.length,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoMeta extends StatelessWidget {
  final Video video;
  final Channel? channel;
  final bool isLoading;

  const _VideoMeta({
    required this.video,
    required this.channel,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasViews = video.viewCount != '0';
    final subscriberLabel = channel != null
        ? '${Formatters.compactCount(channel!.subscriberCount)} ${AppStrings.subscriber}'
        : (isLoading ? AppStrings.loading : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            video.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            [                if (hasViews)
                '${Formatters.compactCount(video.viewCount)} ${AppStrings.views}',
              Formatters.timeAgo(video.publishedAt),
            ].join(' - '),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: video.channelId.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChannelPage(
                                channelId: video.channelId,
                                channelTitle: video.channelTitle,
                                channelAvatarUrl: video.channelAvatarUrl,
                              ),
                            ),
                          ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ChannelAvatar(
                          avatarUrl: video.channelAvatarUrl,
                          channelTitle: video.channelTitle,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.channelTitle,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                subscriberLabel,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  AppStrings.subscribeButton,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionPills(likeCount: video.likeCount),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _CommentsTile(videoId: video.id),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CommentsTile extends StatelessWidget {
  final String videoId;
  const _CommentsTile({required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: videoId.isEmpty
            ? null
            : () => showCommentsSheet(context, videoId: videoId),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.textPrimary,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                AppStrings.commentsTitle,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppDimensions.fontSizeBase,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPills extends StatelessWidget {
  final String likeCount;
  const _ActionPills({required this.likeCount});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _pill(
            child: Row(
              children: [
                const Icon(Icons.thumb_up_outlined, size: 20),
                const SizedBox(width: 8),
                Text(Formatters.compactCount(likeCount)),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 20,
                  color: AppTheme.dividerColor,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.thumb_down_outlined, size: 20),
              ],
            ),
          ),
          _pill(icon: Icons.share_outlined, label: AppStrings.shareLabel),
          _pill(icon: Icons.graphic_eq_outlined, label: AppStrings.remixLabel),
          _pill(icon: Icons.download_outlined, label: AppStrings.downloadLabel),
          _pill(icon: Icons.cut_outlined, label: AppStrings.clipLabel),
        ],
      ),
    );
  }

  Widget _pill({IconData? icon, String? label, Widget? child}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(
        horizontal: label != null ? 12 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child ??
          Row(
            children: [
              Icon(icon, size: 20),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(                    fontSize: AppDimensions.fontSizeMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
  }
}
