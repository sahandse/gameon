import 'package:flutter/material.dart';
import 'package:gameon/src/features/home/presentation/home_screen.dart';
import 'package:gameon/src/features/library/presentation/library_screen.dart';
import 'package:gameon/src/features/profile/presentation/profile_screen.dart';
import 'package:gameon/src/features/search/presentation/game_search_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

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
    _PendingFeature(title: 'Tracker', text: 'Tracker فقط برای بازی‌هایی فعال می‌شود که API واقعی و مجاز برای آمار بازیکن داشته باشند.'),
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

class _PendingFeature extends StatelessWidget {
  const _PendingFeature({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GameonColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GameonColors.border),
              ),
              child: Text(text, style: const TextStyle(color: GameonColors.textSecondary, height: 1.7)),
            ),
          ],
        ),
      ),
    );
  }
}
