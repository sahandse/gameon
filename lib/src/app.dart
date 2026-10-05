import 'package:flutter/material.dart';
import 'package:gameon/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:gameon/src/theme/gameon_theme.dart';

class GameonApp extends StatelessWidget {
  const GameonApp({super.key});

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
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: OnboardingScreen(),
      ),
    );
  }
}
