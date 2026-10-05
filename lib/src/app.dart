import 'package:flutter/material.dart';
import 'package:gameon/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:gameon/src/features/shell/presentation/app_shell.dart';
import 'package:gameon/src/theme/gameon_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameonApp extends StatelessWidget {
  const GameonApp({super.key});

  Future<bool> _hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gameon',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: GameonTheme.dark(),
      locale: const Locale('fa'),
      supportedLocales: const <Locale>[
        Locale('fa'),
        Locale('en'),
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<bool>(
          future: _hasCompletedOnboarding(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _BootScreen();
            }
            return snapshot.data == true
                ? const AppShell()
                : const OnboardingScreen();
          },
        ),
      ),
    );
  }
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
