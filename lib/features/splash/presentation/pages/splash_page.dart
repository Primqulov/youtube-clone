import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../youtube/presentation/bloc/youtube_bloc.dart';
import '../../../youtube/presentation/bloc/youtube_event.dart';
import '../../../youtube/presentation/bloc/youtube_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isDataLoaded = false;
  bool _isAnimationFinished = false;

  @override
  void initState() {
    super.initState();

    context.read<YoutubeBloc>().add(const LoadTrendingVideos());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      if (!mounted) return;

      setState(() {
        _isAnimationFinished = true;
      });

      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (_isAnimationFinished && _isDataLoaded && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const MainShell(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppTheme.surfaceDark;

    return BlocListener<YoutubeBloc, YoutubeState>(
      listener: (context, state) {
        if (state is YoutubeLoaded || state is YoutubeError) {
          if (mounted) {
            setState(() {
              _isDataLoaded = true;
            });
            _checkAndNavigate();
          }
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YoutubeLogoWidget(width: 90),
                  SizedBox(height: 25),
                  Text(
                    AppStrings.appTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontSizeTitle,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class YoutubeLogoWidget extends StatelessWidget {
  final double width;

  const YoutubeLogoWidget({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final double height = width * 0.69;

    return CustomPaint(
      size: Size(width, height),
      painter: YoutubeLogoPainter(),
    );
  }
}

class YoutubeLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height * 0.25),
    );

    canvas.drawRRect(rrect, paint);

    final trianglePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    final triW = size.width * 0.28;
    final triH = size.height * 0.38;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    path.moveTo(centerX - triW / 2.2, centerY - triH / 2);
    path.lineTo(centerX + triW / 1.8, centerY);
    path.lineTo(centerX - triW / 2.2, centerY + triH / 2);
    path.close();

    canvas.drawPath(path, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}