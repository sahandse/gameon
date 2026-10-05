import 'package:flutter/material.dart';
import 'package:gameon/src/features/home/presentation/home_screen.dart';
import 'package:gameon/src/features/library/presentation/library_screen.dart';
import 'package:gameon/src/features/profile/presentation/profile_screen.dart';
import 'package:gameon/src/features/search/presentation/game_search_screen.dart';
import 'package:gameon/src/features/tracker/presentation/tracker_screen.dart';
import 'package:gameon/src/ui/gameon_ux.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    GameSearchScreen(),
    LibraryScreen(),
    TrackerScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) {
                if (value == _index) return;
                GameonHaptics.tap();
                setState(() => _index = value);
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'خانه'),
                NavigationDestination(icon: Icon(Icons.search_rounded), label: 'جستجو'),
                NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'کتابخانه'),
                NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard_rounded), label: 'رتبه'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'من'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
