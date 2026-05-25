import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/youtube_bloc.dart';
import '../bloc/youtube_event.dart';
import '../bloc/youtube_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/video_card.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const double _loadMoreThreshold = 400;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    AppStrings.categoryAll,
    AppStrings.categoryMusic,
    AppStrings.categoryGames,
    AppStrings.categoryNews,
    AppStrings.categorySports,
    AppStrings.categoryEducation,
    AppStrings.categoryTech,
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _scrollController.addListener(_onScroll);
    context.read<YoutubeBloc>().add(const LoadTrendingVideos());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      context.read<YoutubeBloc>().add(const LoadMoreVideos());
    }
  }

  void _onCategoryTap(int index) {
    setState(() => _selectedCategoryIndex = index);
    if (index == 0) {
      context.read<YoutubeBloc>().add(const ClearSearch());
    } else {
      context.read<YoutubeBloc>().add(SearchVideosEvent(_categories[index]));
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<YoutubeBloc>(),
          child: const SearchPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildCategoryChips(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLg,
        AppDimensions.paddingMd,
        AppDimensions.paddingLg,
        AppDimensions.paddingSm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0000), Color(0xFFE60000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(9.5),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(left: 1.5),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: AppDimensions.iconLg,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          const Text(
            AppStrings.appTitle,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeHeadingLg,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _openSearch,
            icon: const Icon(
              Icons.search,
              color: AppTheme.textPrimary,
              size: AppDimensions.iconLg,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          _buildIconButton(Icons.notifications_outlined),
          const SizedBox(width: AppDimensions.paddingXs),
          Container(
            width: AppDimensions.avatarLg,
            height: AppDimensions.avatarLg,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
              ),
            ),
            child: const Center(
              child: Text(
                AppStrings.userAvatarLetter,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppDimensions.fontSizeMd,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.paddingSm),
      child: Icon(icon, color: AppTheme.textPrimary, size: AppDimensions.iconLg),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.paddingSm),
            child: GestureDetector(
              onTap: () => _onCategoryTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMd + 2,
                  vertical: AppDimensions.paddingSm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppTheme.dividerColor,
                    width: AppDimensions.dividerHeight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.surfaceDark
                          : AppTheme.textPrimary,
                      fontSize: AppDimensions.fontSizeMd,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<YoutubeBloc, YoutubeState>(
      builder: (context, state) {
        if (state is YoutubeLoading) return const ShimmerLoading();
        if (state is YoutubeError) return _buildErrorView(state);
        if (state is YoutubeLoaded) {
          if (state.videos.isEmpty) return _buildEmptyView();
          return _buildVideoList(state);
        }
        return const ShimmerLoading();
      },
    );
  }

  Widget _buildVideoList(YoutubeLoaded state) {
    final itemCount = state.videos.length + 1;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceCard,
      onRefresh: () async {
        context.read<YoutubeBloc>().add(
          const LoadTrendingVideos(forceRefresh: true),
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingMd,
          AppDimensions.paddingMd,
          AppDimensions.paddingMd,
          AppDimensions.paddingXl,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == state.videos.length) {
            return _buildFooter(state);
          }
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 80).clamp(0, 1200)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: VideoCard(
              video: state.videos[index],
              recommendedVideos: state.videos,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(YoutubeLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingXl),
        child: Center(
          child: SizedBox(
            width: AppDimensions.progressSize,
            height: AppDimensions.progressSize,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: AppDimensions.progressStroke,
            ),
          ),
        ),
      );
    }
    if (state.hasReachedEnd) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingXl),
        child: Center(
          child: Text(
            AppStrings.endOfList,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: AppDimensions.fontSizeMd,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildErrorView(YoutubeError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.primaryColor,
                size: AppDimensions.iconXxl,
              ),
            ),
            const SizedBox(height: AppDimensions.standardSizedBoxXl),
            const Text(
              AppStrings.errorTitle,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppDimensions.fontSizeXxl,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSm),
            Text(
              state.isNetworkError
                  ? AppStrings.errorNetworkMessage
                  : state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppDimensions.fontSizeBase,
              ),
            ),
            if (!state.isNetworkError) ...[
              const SizedBox(height: AppDimensions.paddingXl),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<YoutubeBloc>().add(const LoadTrendingVideos());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXl,
                    vertical: AppDimensions.paddingMd,
                  ),
                ),
                icon: const Icon(Icons.refresh, size: AppDimensions.iconSm),
                label: const Text(AppStrings.retryButton),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            color: AppTheme.textTertiary,
            size: AppDimensions.iconSuper,
          ),
          const SizedBox(height: AppDimensions.standardSizedBoxLg),
          const Text(
            AppStrings.emptyVideos,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppDimensions.fontSizeLg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
