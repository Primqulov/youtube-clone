import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../youtube/domain/entities/video.dart';
import '../../../youtube/presentation/pages/channel_page.dart';
import '../../../youtube/presentation/widgets/channel_avatar.dart';
import '../../../youtube/presentation/widgets/comments_sheet.dart';

class ShortPlayerItem extends StatefulWidget {
  final Video video;
  final bool isActive;
  final VideoPlayerController? controller;
  final Future<void> Function()? onCommentOpen;

  const ShortPlayerItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.controller,
    this.onCommentOpen,
  });

  @override
  State<ShortPlayerItem> createState() => _ShortPlayerItemState();
}

class _ShortPlayerItemState extends State<ShortPlayerItem> {
  bool _liked = false;
  bool _disliked = false;
  bool _isPaused = false;

  @override
  void didUpdateWidget(covariant ShortPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.isActive != widget.isActive) {
      _isPaused = false;
    }
  }

  bool get _isReady =>
      widget.controller != null &&
      widget.controller!.value.isInitialized;

  void _togglePlayPause() {
    final c = widget.controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _isPaused = true);
    } else {
      c.play();
      setState(() => _isPaused = false);
    }
  }

  void _openChannel() {
    if (widget.video.channelId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelPage(
          channelId: widget.video.channelId,
          channelTitle: widget.video.channelTitle,
          channelAvatarUrl: widget.video.channelAvatarUrl,
        ),
      ),
    );
  }

  Future<void> _openComments() async {
    if (widget.video.id.isEmpty) return;
    await widget.onCommentOpen?.call();
    if (!mounted) return;
    setState(() => _isPaused = true);
    await showCommentsSheet(context, videoId: widget.video.id);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _Background(video: widget.video)),
          if (widget.isActive && _isReady)
            Positioned.fill(child: _NativePlayer(controller: widget.controller!)),
          if (widget.isActive && !_isReady)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2.5,
              ),
            ),
          if (_isPaused && widget.isActive && _isReady)
            const Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 80,
                shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
              ),
            ),
          Positioned(
            right: 8,
            bottom: 100,
            child: _ActionRail(
              video: widget.video,
              liked: _liked,
              disliked: _disliked,
              onLike: () => setState(() {
                _liked = !_liked;
                if (_liked) _disliked = false;
              }),
              onDislike: () => setState(() {
                _disliked = !_disliked;
                if (_disliked) _liked = false;
              }),
              onComment: _openComments,
              onShare: () {},
            ),
          ),
          Positioned(
            left: 16,
            right: 96,
            bottom: 24,
            child: _ShortInfo(
              video: widget.video,
              onChannelTap: _openChannel,
            ),
          ),
          if (widget.isActive && _isReady)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                widget.controller!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppTheme.primaryColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NativePlayer extends StatelessWidget {
  final VideoPlayerController controller;
  const _NativePlayer({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    if (size.width == 0 || size.height == 0) {
      return Container(color: Colors.black);
    }
    return Container(
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  final Video video;
  const _Background({required this.video});

  @override
  Widget build(BuildContext context) {
    if (video.thumbnailUrl.isEmpty) {
      return Container(color: Colors.black);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: video.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: Colors.black),
          errorWidget: (_, _, _) => Container(color: Colors.black),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54, Colors.black87],
              stops: [0.6, 0.85, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRail extends StatelessWidget {
  final Video video;
  final bool liked;
  final bool disliked;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _ActionRail({
    required this.video,
    required this.liked,
    required this.disliked,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: Formatters.compactCount(video.likeCount),
          color: liked ? AppTheme.primaryColor : Colors.white,
          onTap: onLike,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
          label: 'Dislike',
          color: disliked ? AppTheme.primaryColor : Colors.white,
          onTap: onDislike,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.comment_outlined,
          label: 'Izoh',
          color: Colors.white,
          onTap: onComment,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          color: Colors.white,
          onTap: onShare,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.more_vert,
          label: '',
          color: Colors.white,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShortInfo extends StatelessWidget {
  final Video video;
  final VoidCallback onChannelTap;

  const _ShortInfo({required this.video, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onChannelTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChannelAvatar(
                avatarUrl: video.channelAvatarUrl,
                channelTitle: video.channelTitle,
                size: 32,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '@${video.channelTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Subscribe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.3,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
      ],
    );
  }
}
