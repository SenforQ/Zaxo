import 'package:flutter/material.dart';

import '../constants/app_ui.dart';
import 'ai_image_screen.dart';
import 'my_works_screen.dart';
import 'profile_screen.dart';
import 'text_to_music_screen.dart';

const double _tabBarHorizontalMargin = 20;
const double _tabIconSize = 58;

const List<String> _tabNormalAssets = [
  'assets/icon_home_pre.webp',
  'assets/icon_dynamic_pre.webp',
  'assets/icon_work_pre.webp',
  'assets/icon_me_pre.webp',
];

const List<String> _tabActiveAssets = [
  'assets/icon_home_nor.webp',
  'assets/icon_dynamic_nor.webp',
  'assets/icon_work_nor.webp',
  'assets/icon_me_nor.webp',
];

class _TabNavigatorObserver extends NavigatorObserver {
  _TabNavigatorObserver({required this.tabIndex, required this.onStackChanged});

  final int tabIndex;
  final void Function(int tabIndex, int delta) onStackChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      onStackChanged(tabIndex, 1);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onStackChanged(tabIndex, -1);
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  final List<int> _stackDepths = [1, 1, 1, 1];
  final ValueNotifier<int> _selectedTabNotifier = ValueNotifier(0);

  void _onNavigatorStackChanged(int tabIndex, int delta) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _stackDepths[tabIndex] = (_stackDepths[tabIndex] + delta).clamp(1, 999);
      });
    });
  }

  List<Widget> get _screens => [
        Navigator(
          key: ValueKey('tab_0'),
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const TextToMusicScreen()),
          observers: [_TabNavigatorObserver(tabIndex: 0, onStackChanged: _onNavigatorStackChanged)],
        ),
        Navigator(
          key: ValueKey('tab_1'),
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const AiImageScreen()),
          observers: [_TabNavigatorObserver(tabIndex: 1, onStackChanged: _onNavigatorStackChanged)],
        ),
        Navigator(
          key: ValueKey('tab_2'),
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => MyWorksScreen(
              onSwitchToTab: (index) => setState(() => _currentIndex = index),
              selectedTabNotifier: _selectedTabNotifier,
            ),
          ),
          observers: [_TabNavigatorObserver(tabIndex: 2, onStackChanged: _onNavigatorStackChanged)],
        ),
        Navigator(
          key: ValueKey('tab_3'),
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => ProfileScreen(onSwitchToTab: (index) => setState(() => _currentIndex = index)),
          ),
          observers: [_TabNavigatorObserver(tabIndex: 3, onStackChanged: _onNavigatorStackChanged)],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final tabBarWidth = size.width - _tabBarHorizontalMargin * 2;
    final tabBarBottom = bottomPadding + kTabBarBottomGap;
    final showTabBar = _stackDepths[_currentIndex] <= 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/bg_home_nor.webp',
            fit: BoxFit.cover,
          ),
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (showTabBar)
            Positioned(
              left: _tabBarHorizontalMargin,
              right: _tabBarHorizontalMargin,
              bottom: tabBarBottom,
              child: SizedBox(
                width: tabBarWidth,
                height: kTabBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) {
                    return _TabItem(
                      normalAsset: _tabNormalAssets[index],
                      activeAsset: _tabActiveAssets[index],
                      isSelected: _currentIndex == index,
                      onTap: () {
                        setState(() => _currentIndex = index);
                        _selectedTabNotifier.value = index;
                      },
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.normalAsset,
    required this.activeAsset,
    required this.isSelected,
    required this.onTap,
  });

  final String normalAsset;
  final String activeAsset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _tabIconSize,
        height: _tabIconSize,
        child: Image.asset(
          isSelected ? activeAsset : normalAsset,
          width: _tabIconSize,
          height: _tabIconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
