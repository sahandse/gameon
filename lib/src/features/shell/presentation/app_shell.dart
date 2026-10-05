import 'package:flutter/material.dart';
import 'package:gameon/src/features/home/presentation/home_screen.dart';
import 'package:gameon/src/features/library/presentation/library_screen.dart';
import 'package:gameon/src/features/profile/presentation/profile_screen.dart';
import 'package:gameon/src/features/search/presentation/game_search_screen.dart';
import 'package:gameon/src/features/tracker/presentation/tracker_screen.dart';

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
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'جستجو'),
          NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'کتابخانه'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard_rounded), label: 'Tracker'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'من'),
        ],
      ),
    );
  }
}
