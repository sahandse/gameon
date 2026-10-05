import 'package:flutter/material.dart';
import 'package:gameon/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:gameon/src/features/shell/presentation/app_shell.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:gameon/src/ui/gameon_ux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameonApp extends StatefulWidget {
  const GameonApp({super.key});

  @override
  State<GameonApp> createState() => _GameonAppState();
}

class _GameonAppState extends State<GameonApp> {
  late final Future<_BootstrapData> _future = _load();

  Future<_BootstrapData> _load() async {
    final prefs = await SharedPreferences.getInstance();
    return _BootstrapData(
      onboardingCompleted: prefs.getBool('onboarding_completed') ?? false,
      themeChoice: prefs.getString('theme_choice') ?? 'midnight',
    );
  }

  Color _accentFor(String value) => switch (value) {
        'playstation' => const Color(0xFF2F6BFF),
        'xbox' => const Color(0xFF39D353),
        'neon' => const Color(0xFF9D5CFF),
        'oled' => const Color(0xFF19E6C8),
        'light' => const Color(0xFF376DFF),
        _ => GameonColors.accentBlue,
      };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final themeChoice = data?.themeChoice ?? 'midnight';
        final accent = _accentFor(themeChoice);
        return MaterialApp(
          title: 'Gameon',
          debugShowCheckedModeBanner: false,
          themeMode: themeChoice == 'light' ? ThemeMode.light : ThemeMode.dark,
          theme: GameonTheme.light(accent: accent),
          darkTheme: GameonTheme.dark(accent: accent),
          locale: const Locale('fa'),
          supportedLocales: const <Locale>[Locale('fa'), Locale('en')],
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: snapshot.connectionState != ConnectionState.done
                ? const _BootScreen()
                : data!.onboardingCompleted
                    ? const AppShell()
                    : const OnboardingScreen(),
          ),
        );
      },
    );
  }
}

class _BootstrapData {
  const _BootstrapData({required this.onboardingCompleted, required this.themeChoice});
  final bool onboardingCompleted;
  final String themeChoice;
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              GameonAnimatedIn(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    Icons.sports_esports_rounded,
                    size: 38,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'GAMEON',
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
              ),
              const SizedBox(height: 26),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
