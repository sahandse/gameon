import 'package:flutter/material.dart';
import 'package:gameon/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:gameon/src/features/shell/presentation/app_shell.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameonApp extends StatefulWidget {
  const GameonApp({super.key});

  @override
  State<GameonApp> createState() => _GameonAppState();
}

class _GameonAppState extends State<GameonApp> {
  late Future<_BootstrapData> _future = _load();

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
        'light' => const Color(0xFF72A0FF),
        _ => GameonColors.accentBlue,
      };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final accent = _accentFor(data?.themeChoice ?? 'midnight');
        return MaterialApp(
          title: 'Gameon',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: GameonTheme.dark(accent: accent),
          locale: const Locale('fa'),
          supportedLocales: const <Locale>[
            Locale('fa'),
            Locale('en'),
          ],
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
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}
