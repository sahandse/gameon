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
    return _base(
      scheme: scheme.copyWith(
        primary: accent,
        surface: GameonColors.surface,
        onSurface: GameonColors.textPrimary,
      ),
      scaffold: GameonColors.background,
      surface: GameonColors.surface,
      raised: GameonColors.surfaceRaised,
      textSecondary: GameonColors.textSecondary,
      border: GameonColors.border,
    );
  }

  static ThemeData light({Color accent = GameonColors.accentBlue}) {
    const scaffold = Color(0xFFF6F8FC);
    const surface = Color(0xFFFFFFFF);
    const raised = Color(0xFFF0F3F8);
    const secondary = Color(0xFF647084);
    const border = Color(0x140D1B2A);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: surface,
    );
    return _base(
      scheme: scheme.copyWith(primary: accent, surface: surface),
      scaffold: scaffold,
      surface: surface,
      raised: raised,
      textSecondary: secondary,
      border: border,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color surface,
    required Color raised,
    required Color textSecondary,
    required Color border,
  }) {
    final accent = scheme.primary;
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerColor: border,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme().apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: surface.withValues(alpha: .97),
        indicatorColor: accent.withValues(alpha: .14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
              fontSize: 11.5,
            )),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        hintStyle: TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent, width: 1.25),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
    );
  }
}
