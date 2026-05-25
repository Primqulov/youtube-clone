import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_dimensions.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/shorts/presentation/pages/shorts_page.dart';
import '../features/subscriptions/presentation/pages/subscriptions_page.dart';
import '../features/youtube/presentation/bloc/youtube_bloc.dart';
import '../features/youtube/presentation/pages/home_page.dart';
import '../injection_container.dart' as di;

class MainShellScope extends InheritedNotifier<ValueNotifier<int>> {
  const MainShellScope({
    super.key,
    required ValueNotifier<int> selectedTab,
    required super.child,
  }) : super(notifier: selectedTab);

  static int? selectedTabOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MainShellScope>();
    return scope?.notifier?.value;
  }

  static const int homeTabIndex = 0;
  static const int shortsTabIndex = 1;
  static const int subscriptionsTabIndex = 2;
  static const int libraryTabIndex = 3;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ValueNotifier<int> _selectedTab = ValueNotifier<int>(0);

  late final List<Widget> _pages = [
    BlocProvider(
      create: (_) => di.sl<YoutubeBloc>(),
      child: const HomePage(),
    ),
    const ShortsPage(),
    const SubscriptionsPage(),
    const LibraryPage(),
  ];

  @override
  void dispose() {
    _selectedTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      selectedTab: _selectedTab,
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedTab,
        builder: (context, index, _) {
          return Scaffold(
            backgroundColor: AppTheme.surfaceDark,
            body: IndexedStack(index: index, children: _pages),
            bottomNavigationBar: _buildBottomNav(index),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(int index) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => _selectedTab.value = i,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.textPrimary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: AppDimensions.bottomNavFontSize,
        unselectedFontSize: AppDimensions.bottomNavFontSize,
        showUnselectedLabels: true,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.navHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle_fill),
            label: AppStrings.navShorts,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_outlined),
            activeIcon: Icon(Icons.subscriptions),
            label: AppStrings.navSubscriptions,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: AppStrings.navLibrary,
          ),
        ],
      ),
    );
  }
}
