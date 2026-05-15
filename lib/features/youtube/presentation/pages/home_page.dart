import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/video.dart';
import '../bloc/youtube_bloc.dart';
import '../bloc/youtube_event.dart';
import '../bloc/youtube_state.dart';
import '../widgets/video_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/shimmer_loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Trendda',
    'Musiqa',
    'O\'yinlar',
    'Yangiliklar',
    'Sport',
    'Ta\'lim',
    'Texnologiya',
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
    context.read<YoutubeBloc>().add(const LoadTrendingVideos());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    setState(() => _selectedCategoryIndex = index);
    if (index == 0) {
      context.read<YoutubeBloc>().add(const ClearSearch());
    } else {
      context.read<YoutubeBloc>().add(SearchVideosEvent(_categories[index]));
    }
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Logo row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'YouTube',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _buildIconButton(Icons.cast_outlined),
              _buildIconButton(Icons.notifications_outlined),
              const SizedBox(width: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400,
                      Colors.blue.shade400,
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          SearchBarWidget(
            onSearch: (query) {
              setState(() => _selectedCategoryIndex = -1);
              context.read<YoutubeBloc>().add(SearchVideosEvent(query));
            },
            onClear: () {
              setState(() => _selectedCategoryIndex = 0);
              context.read<YoutubeBloc>().add(const ClearSearch());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Icon(icon, color: AppTheme.textPrimary, size: 22),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onCategoryTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppTheme.dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? AppTheme.surfaceDark : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
        if (state is YoutubeLoading) {
          return const ShimmerLoading();
        }

        if (state is YoutubeError) {
          return _buildErrorView(state.message);
        }

        if (state is YoutubeLoaded) {
          if (state.videos.isEmpty) {
            return _buildEmptyView(state.isSearchResult);
          }
          return _buildVideoList(state.videos, state.isSearchResult, state.searchQuery);
        }

        return const ShimmerLoading();
      },
    );
  }

  Widget _buildVideoList(List<Video> videos, bool isSearch, String query) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceCard,
      onRefresh: () async {
        if (isSearch) {
          context.read<YoutubeBloc>().add(SearchVideosEvent(query));
        } else {
          context.read<YoutubeBloc>().add(const LoadTrendingVideos());
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 80)),
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
            child: VideoCard(video: videos[index]),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Xatolik yuz berdi',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<YoutubeBloc>().add(const LoadTrendingVideos());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.video_library_outlined,
            color: AppTheme.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Videolar topilmadi' : 'Hozircha videolar yo\'q',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
