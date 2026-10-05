import 'package:flutter/material.dart';
import 'package:gameon/src/features/onboarding/presentation/onboarding_screen.dart';
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
            if (snapshot.data == true) {
              return const _ReadyForDataScreen();
            }
            return const OnboardingScreen();
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

class _ReadyForDataScreen extends StatelessWidget {
  const _ReadyForDataScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAMEON',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              Text(
                'پروفایل تو آماده است',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'منابع دیتای واقعی بازی‌ها در مرحله بعد متصل می‌شوند. تا آن زمان Gameon عمداً هیچ بازی، قیمت، خبر یا رتبه‌ی آزمایشی نمایش نمی‌دهد.',
                style: TextStyle(
                  color: GameonColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
