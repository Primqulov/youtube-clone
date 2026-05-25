import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../../youtube/presentation/bloc/youtube_bloc.dart';
import '../../../youtube/presentation/pages/search_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      color: AppTheme.primaryColor,
                      size: 72,
                    ),
                    SizedBox(height: 20),
                    Text(
                      AppStrings.libraryTitle,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppDimensions.fontSizeHeadingLg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppDimensions.paddingSm),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingXxl),
                      child: Text(
                        AppStrings.librarySubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLg,
        AppDimensions.paddingMd,
        AppDimensions.paddingLg,
        AppDimensions.paddingSm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.video_library_outlined,
            color: AppTheme.primaryColor,
            size: AppDimensions.iconJumbo,
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          const Text(
            AppStrings.libraryTitle,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeHeadingLg,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
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
            icon: const Icon(
              Icons.search,
              color: AppTheme.textPrimary,
              size: AppDimensions.iconLg,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
