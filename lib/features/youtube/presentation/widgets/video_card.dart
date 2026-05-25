import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/video.dart';
import '../pages/video_player_page.dart';
import 'channel_avatar.dart';

class VideoCard extends StatelessWidget {
  final Video video;
  final List<Video> recommendedVideos;

  const VideoCard({
    super.key,
    required this.video,
    this.recommendedVideos = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerPage(
            video: video,
            recommendedVideos: recommendedVideos,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(video: video),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChannelAvatar(
                    avatarUrl: video.channelAvatarUrl,
                    channelTitle: video.channelTitle,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _MetaInfo(video: video)),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Video video;
  const _Thumbnail({required this.video});

  @override
  Widget build(BuildContext context) {
    final hasUrl = video.thumbnailUrl.isNotEmpty;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: hasUrl
                ? CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 220),
                    placeholder: (_, _) => const _ThumbnailPlaceholder(
                      icon: Icons.play_circle_outline,
                    ),
                    errorWidget: (_, _, _) => const _ThumbnailPlaceholder(
                      icon: Icons.error_outline,
                    ),
                  )
                : const _ThumbnailPlaceholder(
                    icon: Icons.play_circle_outline,
                  ),
          ),
        ),
        if (hasUrl && video.duration.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                video.duration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  final IconData icon;
  const _ThumbnailPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceCard,
      child: Center(
        child: Icon(icon, color: AppTheme.textTertiary, size: 40),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final Video video;
  const _MetaInfo({required this.video});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      video.channelTitle,
      if (video.viewCount != '0')
        '${Formatters.compactCount(video.viewCount)} ${AppStrings.views}',
      Formatters.timeAgo(video.publishedAt),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          parts.join(AppStrings.separatorDash),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
