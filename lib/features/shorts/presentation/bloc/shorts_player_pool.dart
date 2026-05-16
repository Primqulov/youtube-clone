import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;

class ShortsPlayerPool {
  final int windowRadius;
  final void Function() onChange;
  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, VideoPlayerController> _ready = {};
  final Set<String> _loading = {};
  final Set<String> _wanted = {};
  String? _activeId;
  bool _externallyPaused = false;

  ShortsPlayerPool({this.windowRadius = 1, required this.onChange});

  VideoPlayerController? get(String videoId) => _ready[videoId];

  Future<void> updateWindow({
    required List<String> orderedIds,
    required int currentIndex,
  }) async {
    final wanted = <String>{};
    for (
      var i = currentIndex - windowRadius;
      i <= currentIndex + windowRadius;
      i++
    ) {
      if (i >= 0 && i < orderedIds.length) {
        final id = orderedIds[i];
        if (id.isNotEmpty) wanted.add(id);
      }
    }
    _wanted
      ..clear()
      ..addAll(wanted);

    _activeId = (currentIndex >= 0 && currentIndex < orderedIds.length)
        ? orderedIds[currentIndex]
        : null;
    _externallyPaused = false;

    final toEvict = _ready.keys.where((id) => !wanted.contains(id)).toList();
    for (final id in toEvict) {
      await _ready.remove(id)?.dispose();
    }

    for (final entry in _ready.entries) {
      final ctrl = entry.value;
      if (entry.key == _activeId) {
        unawaited(_resumeActive(ctrl));
      } else if (ctrl.value.isPlaying) {
        unawaited(ctrl.pause());
      }
    }

    for (final id in wanted) {
      if (!_ready.containsKey(id) && !_loading.contains(id)) {
        unawaited(_prepare(id));
      }
    }
  }

  Future<void> _resumeActive(VideoPlayerController ctrl) async {
    if (ctrl.value.isPlaying) return;
    if (ctrl.value.position > Duration.zero) {
      await ctrl.seekTo(Duration.zero);
    }
    await ctrl.play();
  }

  Future<void> _prepare(String videoId) async {
    _loading.add(videoId);
    VideoPlayerController? controller;
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final stream = _pickStream(manifest);
      if (stream == null) return;
      if (!_wanted.contains(videoId)) return;

      controller = VideoPlayerController.networkUrl(stream.url);
      await controller.initialize();
      if (!_wanted.contains(videoId)) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);

      _ready[videoId] = controller;

      if (videoId == _activeId && !_externallyPaused) {
        unawaited(_resumeActive(controller));
      }

      onChange();
    } catch (_) {
      await controller?.dispose();
    } finally {
      _loading.remove(videoId);
    }
  }

  MuxedStreamInfo? _pickStream(StreamManifest manifest) {
    if (manifest.muxed.isEmpty) return null;
    final under480 = manifest.muxed
        .where((s) => s.videoResolution.height <= 480)
        .toList();
    final pool = under480.isNotEmpty ? under480 : manifest.muxed.toList();
    pool.sort((a, b) => b.bitrate.compareTo(a.bitrate));
    return pool.first;
  }

  Future<void> pauseAll() async {
    _externallyPaused = true;
    for (final c in _ready.values) {
      if (c.value.isPlaying) {
        await c.pause();
      }
    }
  }

  Future<void> dispose() async {
    _wanted.clear();
    _activeId = null;
    for (final c in _ready.values) {
      await c.dispose();
    }
    _ready.clear();
    _loading.clear();
    _yt.close();
  }
}
