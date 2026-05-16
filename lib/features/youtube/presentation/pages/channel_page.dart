import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/channel.dart';
import '../bloc/channel_cubit.dart';
import '../widgets/channel_avatar.dart';
import '../widgets/video_card.dart';

class ChannelPage extends StatelessWidget {
  final String channelId;
  final String channelTitle;
  final String? channelAvatarUrl;

  const ChannelPage({
    super.key,
    required this.channelId,
    required this.channelTitle,
    this.channelAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final seed = Channel(
      id: channelId,
      title: channelTitle,
      description: '',
      thumbnailUrl: channelAvatarUrl ?? '',
    );
    return BlocProvider(
      create: (_) => di.sl<ChannelCubit>(
        param1: channelId,
        param2: seed,
      )..load(),
      child: const _ChannelView(),
    );
  }
}

class _ChannelView extends StatefulWidget {
  const _ChannelView();

  @override
  State<_ChannelView> createState() => _ChannelViewState();
}

class _ChannelViewState extends State<_ChannelView> {
  static const double _loadMoreThreshold = 400;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      context.read<ChannelCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: BlocBuilder<ChannelCubit, ChannelPageState>(
          builder: (context, state) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.surfaceDark,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  title: Text(
                    state.channel?.title ?? '',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ChannelHeader(state: state),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'Videolar',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.isLoading && state.videos.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                else if (state.videos.isEmpty &&
                    state.errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorView(message: state.errorMessage!),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == state.videos.length) {
                          return _Footer(state: state);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: VideoCard(
                            video: state.videos[index],
                            recommendedVideos: state.videos,
                          ),
                        );
                      },
                      childCount: state.videos.length + 1,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChannelHeader extends StatelessWidget {
  final ChannelPageState state;
  const _ChannelHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final channel = state.channel;
    final avatarUrl = channel?.thumbnailUrl ?? '';
    final title = channel?.title ?? '';
    final subscribers = channel != null
        ? '${Formatters.compactCount(channel.subscriberCount)} obunachi'
        : (state.isLoading ? 'Yuklanmoqda...' : '');
    final videoCount = channel != null
        ? '${Formatters.compactCount(channel.videoCount)} video'
        : '';
    final description = channel?.description ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChannelAvatar(
                avatarUrl: avatarUrl,
                channelTitle: title,
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (subscribers.isNotEmpty) subscribers,
                        if (videoCount.isNotEmpty) videoCount,
                      ].join(' • '),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Subscribe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ChannelPageState state;
  const _Footer({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }
    if (state.hasReachedEnd && state.videos.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Oxiri',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.textTertiary,
            size: 48,
          ),
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
    );
  }
}
