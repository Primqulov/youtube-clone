import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/video.dart';
import '../widgets/video_card.dart';

class VideoPlayerPage extends StatefulWidget {
  final Video video;
  final List<Video> recommendedVideos;

  const VideoPlayerPage({
    super.key,
    required this.video,
    this.recommendedVideos = const [],
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final WebViewController _controller;
  late final List<Video> _recommendedVideos;
  bool _isLoading = true;
  bool _isFullscreen = false;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _recommendedVideos = _buildRecommendations();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress / 100);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller.loadRequest(
      Uri.parse(_buildPlayerUrl()),
      headers: const {
        'Referer': 'https://com.example.exsampleflutter/',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (mounted) {
      setState(() => _isFullscreen = true);
    }
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      setState(() => _isFullscreen = false);
    }
  }

  String _formatCount(String count) {
    final number = int.tryParse(count) ?? 0;
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return count;
  }

  List<Video> _buildRecommendations() {
    final seenVideoIds = <String>{widget.video.id};
    final videos = <Video>[];

    for (final video in widget.recommendedVideos) {
      if (video.id.isEmpty || !seenVideoIds.add(video.id)) continue;
      videos.add(video);
    }

    videos.shuffle(Random());
    return videos;
  }

  String _buildPlayerUrl() {
    final videoId = Uri.encodeComponent(widget.video.id);

    return 'https://www.youtube.com/embed/$videoId'
        '?autoplay=0'
        '&playsinline=1'
        '&controls=1'
        '&rel=0'
        '&modestbranding=1'
        '&iv_load_policy=3';
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _exitFullscreen();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _FullscreenVideoPlayer(
            controller: _controller,
            isLoading: _isLoading,
            loadingProgress: _loadingProgress,
            onExit: _exitFullscreen,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _VideoPlayerHeader(
                controller: _controller,
                isLoading: _isLoading,
                loadingProgress: _loadingProgress,
                onBack: () => Navigator.pop(context),
                onFullscreen: _enterFullscreen,
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      widget.video.title,
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
                      '${_formatCount(widget.video.viewCount)} views - 2 days ago',
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
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.surfaceElevated,
                          child: Text(
                            widget.video.channelTitle.isNotEmpty
                                ? widget.video.channelTitle[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.video.channelTitle,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                '1.5M subscribers',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                            'Subscribe',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _buildActionPill(
                          child: Row(
                            children: [
                              const Icon(Icons.thumb_up_outlined, size: 20),
                              const SizedBox(width: 8),
                              const Text('120K'),
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
                        _buildActionPill(
                          icon: Icons.share_outlined,
                          label: 'Share',
                        ),
                        _buildActionPill(
                          icon: Icons.graphic_eq_outlined,
                          label: 'Remix',
                        ),
                        _buildActionPill(
                          icon: Icons.download_outlined,
                          label: 'Download',
                        ),
                        _buildActionPill(
                          icon: Icons.cut_outlined,
                          label: 'Clip',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Comments',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '1.2K',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const Spacer(),
                              const Icon(Icons.unfold_more, size: 18),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This video is amazing! Keep up the great work.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            if (_recommendedVideos.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: VideoCard(
                      video: _recommendedVideos[index],
                      recommendedVideos: widget.recommendedVideos,
                    ),
                  );
                }, childCount: _recommendedVideos.length),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    IconData? icon,
    Widget? customIcon,
    String? label,
    Widget? child,
  }) {
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
      child:
          child ??
          Row(
            children: [
              customIcon ?? Icon(icon, size: 20),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
    );
  }
}

class _VideoPlayerHeader extends StatelessWidget {
  final WebViewController controller;
  final bool isLoading;
  final double loadingProgress;
  final VoidCallback onBack;
  final VoidCallback onFullscreen;

  const _VideoPlayerHeader({
    required this.controller,
    required this.isLoading,
    required this.loadingProgress,
    required this.onBack,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: WebViewWidget(controller: controller),
          ),
          if (isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: loadingProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                minHeight: 2,
              ),
            ),
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Fullscreen',
                onPressed: onFullscreen,
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatelessWidget {
  final WebViewController controller;
  final bool isLoading;
  final double loadingProgress;
  final VoidCallback onExit;

  const _FullscreenVideoPlayer({
    required this.controller,
    required this.isLoading,
    required this.loadingProgress,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: WebViewWidget(controller: controller),
        ),
        if (isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: loadingProgress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
              minHeight: 2,
            ),
          ),
        Positioned(
          top: 12,
          left: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Back',
              onPressed: onExit,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Exit fullscreen',
              onPressed: onExit,
              icon: const Icon(
                Icons.fullscreen_exit,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
