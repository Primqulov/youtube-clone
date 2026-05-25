import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/route_observer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../../youtube/domain/entities/video.dart';
import '../../../youtube/presentation/bloc/youtube_bloc.dart';
import '../../../youtube/presentation/pages/search_page.dart';
import '../bloc/shorts_cubit.dart';
import '../bloc/shorts_player_pool.dart';
import '../widgets/short_player_item.dart';

class ShortsPage extends StatelessWidget {
  const ShortsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ShortsCubit>()..load(),
      child: const _ShortsView(),
    );
  }
}

class _ShortsView extends StatelessWidget {
  const _ShortsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ShortsCubit, ShortsState>(
        builder: (context, state) {
          if (state.isLoading && state.videos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }
          if (state.errorMessage != null && state.videos.isEmpty) {
            return _ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<ShortsCubit>().load(),
            );
          }
          if (state.videos.isEmpty) {
            return _ErrorView(
              message: AppStrings.shortsNotFound,
              onRetry: () => context.read<ShortsCubit>().load(),
            );
          }
          return _ShortsFeed(videos: state.videos);
        },
      ),
    );
  }
}

class _ShortsFeed extends StatefulWidget {
  final List<Video> videos;
  const _ShortsFeed({required this.videos});

  @override
  State<_ShortsFeed> createState() => _ShortsFeedState();
}

class _ShortsFeedState extends State<_ShortsFeed> with RouteAware {
  static const int _prefetchThreshold = 3;
  final PageController _pageController = PageController();
  late final ShortsPlayerPool _pool;
  int _currentIndex = 0;
  bool? _wasTabVisible;
  bool _routePaused = false;

  @override
  void initState() {
    super.initState();
    _pool = ShortsPlayerPool(
      onChange: () {
        if (mounted) setState(() {});
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWindow());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
    final selectedTab = MainShellScope.selectedTabOf(context);
    final tabVisible =
        selectedTab == null || selectedTab == MainShellScope.shortsTabIndex;
    if (_wasTabVisible == true && !tabVisible) {
      _pool.pauseAll();
    } else if (_wasTabVisible == false && tabVisible && !_routePaused) {
      _syncWindow();
    }
    _wasTabVisible = tabVisible;
  }

  @override
  void didPushNext() {
    _routePaused = true;
    _pool.pauseAll();
  }

  @override
  void didPopNext() {
    _routePaused = false;
    if (_wasTabVisible ?? true) _syncWindow();
  }

  @override
  void didUpdateWidget(covariant _ShortsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videos.length != oldWidget.videos.length) {
      _syncWindow();
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _pool.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _syncWindow() {
    if (!mounted) return;
    final selectedTab = MainShellScope.selectedTabOf(context);
    final isVisible =
        selectedTab == null || selectedTab == MainShellScope.shortsTabIndex;
    _pool.updateWindow(
      orderedIds: widget.videos.map((v) => v.id).toList(),
      currentIndex: _currentIndex,
    );

    if (!isVisible || _routePaused) {
      _pool.pauseAll();
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _syncWindow();
    if (index >= widget.videos.length - _prefetchThreshold) {
      context.read<ShortsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: widget.videos.length,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            return ShortPlayerItem(
              key: ValueKey(video.id),
              video: video,
              isActive: index == _currentIndex,
              controller: _pool.get(video.id),
              onCommentOpen: _pool.pauseAll,
            );
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Shorts IndexedStack ichida — back o'rniga home tabga o'tamiz
                      final scope = context.findAncestorWidgetOfExactType<MainShellScope>();
                      scope?.notifier?.value = MainShellScope.homeTabIndex;
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    AppStrings.shortsTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontSizeXxl,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => di.sl<YoutubeBloc>(),
                            child: const SearchPage(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(AppStrings.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
