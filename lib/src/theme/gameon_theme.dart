import 'package:flutter/material.dart';

abstract final class GameonColors {
  static const background = Color(0xFF07090D);
  static const surface = Color(0xFF10141B);
  static const surfaceRaised = Color(0xFF171C25);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFF9CA6B5);
  static const border = Color(0x1FFFFFFF);
  static const accentBlue = Color(0xFF2F80FF);
  static const accentCyan = Color(0xFF2EE6D6);
}

abstract final class GameonTheme {
  static ThemeData dark({Color accent = GameonColors.accentBlue}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: GameonColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameonColors.background,
      colorScheme: scheme.copyWith(
        primary: accent,
        surface: GameonColors.surface,
        onSurface: GameonColors.textPrimary,
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerColor: GameonColors.border,
      cardTheme: const CardThemeData(
        color: GameonColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: GameonColors.surface.withValues(alpha: .96),
        indicatorColor: accent.withValues(alpha: .14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GameonColors.surfaceRaised,
        hintStyle: const TextStyle(color: GameonColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: GameonColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
