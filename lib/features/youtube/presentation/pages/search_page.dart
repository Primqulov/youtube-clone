import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/search_history_cache.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/youtube_bloc.dart';
import '../bloc/youtube_event.dart';
import '../bloc/youtube_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/video_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SearchHistoryCache _historyCache = di.sl<SearchHistoryCache>();
  final ScrollController _scrollController = ScrollController();

  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const threshold = 400.0;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      final state = context.read<YoutubeBloc>().state;
      if (state is YoutubeLoaded && !state.isLoadingMore && !state.hasReachedEnd) {
        context.read<YoutubeBloc>().add(const LoadMoreVideos());
      }
    }
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _historyCache.addQuery(trimmed);
    setState(() => _showHistory = false);
    context.read<YoutubeBloc>().add(SearchVideosEvent(trimmed));
    FocusScope.of(context).unfocus();
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _showHistory = true);
    context.read<YoutubeBloc>().add(const ClearSearch());
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingSm,
        AppDimensions.paddingMd,
        AppDimensions.paddingSm,
        AppDimensions.paddingSm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.read<YoutubeBloc>().add(const ClearSearch());
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingXs),
          Expanded(
            child: Container(
              height: AppDimensions.searchBarHeight,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppTheme.dividerColor,
                  width: AppDimensions.dividerHeight,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppDimensions.paddingMd),
                  const Icon(
                    Icons.search,
                    color: AppTheme.textTertiary,
                    size: AppDimensions.iconMd,
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _performSearch,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppDimensions.fontSizeBase,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: const InputDecoration(
                        hintText: AppStrings.searchHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _showHistory = true);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(AppDimensions.paddingSm),
                        child: Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                          size: AppDimensions.iconSm,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingXs),
          TextButton(
            onPressed: _clearSearch,
            child: const Text(
              AppStrings.categoryAll,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppDimensions.fontSizeBase,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_showHistory) {
      return _buildHistoryView();
    }
    return _buildResultsView();
  }

  Widget _buildHistoryView() {
    final history = _historyCache.getQueries();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingLg,
              AppDimensions.paddingSm,
              AppDimensions.paddingLg,
              AppDimensions.paddingSm,
            ),
            child: Row(
              children: [
                const Text(
                  'So\'nggi qidiruvlar',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppDimensions.fontSizeXl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _historyCache.clear();
                    setState(() {});
                  },
                  child: const Text(
                    'Tozalash',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppDimensions.fontSizeBase,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (history.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    color: AppTheme.textTertiary,
                    size: AppDimensions.iconSuper,
                  ),
                  const SizedBox(height: AppDimensions.paddingLg),
                  const Text(
                    'Qidiruv tarixi bo\'sh',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppDimensions.fontSizeLg,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSm),
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(
                color: AppTheme.dividerColor,
                height: 0.5,
                indent: AppDimensions.paddingXl + AppDimensions.paddingMd,
              ),
              itemBuilder: (context, index) {
                final query = history[index];
                return ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppTheme.textSecondary,
                    size: AppDimensions.iconMd,
                  ),
                  title: Text(
                    query,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppDimensions.fontSizeBase,
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      _historyCache.removeQuery(query);
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close,
                      color: AppTheme.textTertiary,
                      size: AppDimensions.iconSm,
                    ),
                  ),
                  onTap: () => _onHistoryTap(query),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildResultsView() {
    return BlocBuilder<YoutubeBloc, YoutubeState>(
      builder: (context, state) {
        if (state is YoutubeLoading) {
          return const ShimmerLoading();
        }
        if (state is YoutubeError) {
          return _buildErrorView(state);
        }
        if (state is YoutubeLoaded) {
          if (state.videos.isEmpty) {
            return _buildEmptyView();
          }
          return _buildVideoList(state);
        }
        return const SizedBox.shrink();
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
          SearchVideosEvent(state.searchQuery),
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
            return _buildLoadMoreFooter(state);
          }
          return VideoCard(
            video: state.videos[index],
            recommendedVideos: state.videos,
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreFooter(YoutubeLoaded state) {
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
                  context.read<YoutubeBloc>().add(SearchVideosEvent(
                    _searchController.text.trim(),
                  ));
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
            Icons.search_off,
            color: AppTheme.textTertiary,
            size: AppDimensions.iconSuper,
          ),
          const SizedBox(height: AppDimensions.standardSizedBoxLg),
          const Text(
            AppStrings.emptySearch,
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
