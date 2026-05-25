import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

class NativeVideoPlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final VoidCallback? onBack;

  const NativeVideoPlayer({
    super.key,
    required this.videoId,
    this.autoPlay = true,
    this.onBack,
  });

  @override
  NativeVideoPlayerState createState() => NativeVideoPlayerState();
}

class NativeVideoPlayerState extends State<NativeVideoPlayer> {
  final YoutubeExplode _yt = YoutubeExplode();
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;
  bool _isFullscreen = false;
  Timer? _controlsTimer;
  double? _aspectRatio;

  /// Tashqaridan pauza qilish uchun
  void pause() {
    _controller?.pause();
    _controlsTimer?.cancel();
    if (mounted) setState(() => _showControls = true);
  }

  /// Tashqaridan davom ettirish uchun
  void play() {
    _controller?.play();
    _startControlsTimer();
  }

  bool get isPlaying => _controller?.value.isPlaying ?? false;

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(widget.videoId);
      final streamInfo = _pickBestStream(manifest);

      if (streamInfo == null) {
        if (mounted) {
          setState(() {
            _errorMessage = AppStrings.videoStreamNotFound;
            _isLoading = false;
          });
        }
        return;
      }

      final controller = VideoPlayerController.networkUrl(streamInfo.url);
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      _aspectRatio = controller.value.size.width > 0 && controller.value.size.height > 0
          ? controller.value.aspectRatio
          : 16 / 9;

      controller.addListener(_onPlayerUpdate);

      if (widget.autoPlay) {
        await controller.play();
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      _startControlsTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${AppStrings.videoLoadErrorPrefix}: $e';
          _isLoading = false;
        });
      }
    }
  }

  MuxedStreamInfo? _pickBestStream(StreamManifest manifest) {
    if (manifest.muxed.isEmpty) return null;
    final preferred = manifest.muxed
        .where((s) => s.videoResolution.height <= 720)
        .toList();
    if (preferred.isNotEmpty) {
      preferred.sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
      return preferred.first;
    }
    final sorted = manifest.muxed.toList();
    sorted.sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
    return sorted.first;
  }

  void _onPlayerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !_isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _showControls = true);
      _controlsTimer?.cancel();
    } else {
      c.play();
      _startControlsTimer();
    }
  }

  void _seekTo(double position) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration;
    final seekPos = duration * position;
    c.seekTo(seekPos);
  }

  Future<void> _toggleFullscreen() async {
    final newFullscreen = !_isFullscreen;
    if (newFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() => _isFullscreen = newFullscreen);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    _yt.close();
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initPlayer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppStrings.retryButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(color: Colors.black),
      );
    }

    final c = _controller!;
    final duration = c.value.duration;
    final position = c.value.position;
    final bufferPercent = c.value.buffered.isNotEmpty
        ? c.value.buffered.last.end.inMilliseconds /
            (duration.inMilliseconds > 0 ? duration.inMilliseconds : 1)
        : 0.0;
    final playPercent = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: _aspectRatio ?? 16 / 9,
        child: Stack(
          children: [
            Container(color: Colors.black, child: Center(child: VideoPlayer(c))),
            if (_showControls)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showControls)
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_isFullscreen) {
                            _toggleFullscreen();
                          } else {
                            widget.onBack?.call();
                            Navigator.maybePop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      if (_isFullscreen)
                        IconButton(
                          onPressed: _toggleFullscreen,
                          icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                        ),
                    ],
                  ),
                ),
              ),
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: Icon(
                      c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white, size: 40,
                    ),
                  ),
                ),
              ),
            if (_showControls)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _buildBottomControls(c, duration, position, bufferPercent, playPercent),
              ),
            if (!_showControls)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _buildMiniProgressBar(playPercent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    VideoPlayerController c, Duration duration, Duration position,
    double bufferPercent, double playPercent,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressBar(
              controller: c, onSeek: _seekTo,
              bufferPercent: bufferPercent, playPercent: playPercent,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${_formatDuration(position)}${AppStrings.separatorTime}${_formatDuration(duration)}',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleFullscreen,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.fullscreen, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniProgressBar(double playPercent) {
    return Container(
      height: 3, color: Colors.white24,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: playPercent.clamp(0.0, 1.0),
        child: Container(color: AppTheme.primaryColor),
      ),
    );
  }
}

class VideoProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  final void Function(double) onSeek;
  final double bufferPercent;
  final double playPercent;

  const VideoProgressBar({
    super.key,
    required this.controller,
    required this.onSeek,
    required this.bufferPercent,
    required this.playPercent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onTapDown: (details) {
            onSeek((details.localPosition.dx / width).clamp(0.0, 1.0));
          },
          onHorizontalDragUpdate: (details) {
            onSeek((details.localPosition.dx / width).clamp(0.0, 1.0));
          },
          child: Container(
            height: 32,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Container(height: 3, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(1.5))),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: bufferPercent.clamp(0.0, 1.0),
                  child: Container(height: 3, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(1.5))),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: playPercent.clamp(0.0, 1.0),
                  child: Container(height: 3, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(1.5))),
                ),
                Positioned(
                  left: (playPercent.clamp(0.0, 1.0) * width) - 6,
                  top: 0,
                  child: Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentColor)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
