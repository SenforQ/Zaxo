import 'package:flutter/material.dart';

import '../constants/app_ui.dart';
import 'ai_image_screen.dart';
import 'my_works_screen.dart';
import 'profile_screen.dart';
import 'text_to_music_screen.dart';

const List<BottomNavigationBarItem> _tabItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.image_outlined),
    activeIcon: Icon(Icons.image),
    label: 'AI',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.folder_outlined),
    activeIcon: Icon(Icons.folder),
    label: 'Works',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outlined),
    activeIcon: Icon(Icons.person),
    label: 'Me',
  ),
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
    final showTabBar = _stackDepths[_currentIndex] <= 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: kHomeBackgroundGradient,
            ),
          ),
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ],
      ),
      bottomNavigationBar: showTabBar
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                  _selectedTabNotifier.value = index;
                },
                items: _tabItems,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white.withValues(alpha: 0.75),
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }
}
