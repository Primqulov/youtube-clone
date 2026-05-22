import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChannelAvatar extends StatelessWidget {
  final String avatarUrl;
  final String channelTitle;
  final double size;

  const ChannelAvatar({
    super.key,
    required this.avatarUrl,
    required this.channelTitle,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      if (kDebugMode) {
        print("hello");
      }
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _Fallback(title: channelTitle, size: size),
          errorWidget: (_, _, _) =>
              _Fallback(title: channelTitle, size: size),
        ),
      );
    }
    return _Fallback(title: channelTitle, size: size);
  }
}

class _Fallback extends StatelessWidget {
  final String title;
  final double size;

  const _Fallback({required this.title, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.accentColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
