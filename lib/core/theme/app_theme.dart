import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Semantic color tokens for Loki's light and dark themes.
@immutable
final class AppColors {
  const AppColors({
    required this.brightness,
    required this.primary,
    required this.primarySoft,
    required this.accentAmber,
    required this.accentAmberSoft,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.danger,
  });

  final Brightness brightness;
  final Color primary;
  final Color primarySoft;
  final Color accentAmber;
  final Color accentAmberSoft;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color danger;

  bool get isDark => brightness == Brightness.dark;
}

/// Centralized Light & Dark theme tokens (Soft Red primary + Streak Amber).
final class AppTheme {
  AppTheme._();

  static const Color primaryLight = Color(0xFFE55353);
  static const Color primaryDark = Color(0xFFFF7A7A);
  static const Color streakAmberLight = Color(0xFFD97706);
  static const Color streakAmberDark = Color(0xFFFBBF24);

  static const AppColors lightColors = AppColors(
    brightness: Brightness.light,
    primary: primaryLight,
    primarySoft: Color(0x16E55353),
    accentAmber: streakAmberLight,
    accentAmberSoft: Color(0x18D97706),
    background: Color(0xFFF8F6F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3EFEF),
    border: Color(0xFFEBE5E5),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    danger: Color(0xFFDC2626),
  );

  static const AppColors darkColors = AppColors(
    brightness: Brightness.dark,
    primary: primaryDark,
    primarySoft: Color(0x22FF7A7A),
    accentAmber: streakAmberDark,
    accentAmberSoft: Color(0x22FBBF24),
    background: Color(0xFF0B0D11),
    surface: Color(0xFF151820),
    surfaceMuted: Color(0xFF1E222D),
    border: Color(0xFF262B36),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    danger: Color(0xFFF87171),
  );

  static AppColors colors(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColors : lightColors;
  }

  static CupertinoThemeData cupertinoFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final c = isDark ? darkColors : lightColors;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: c.primary,
      primaryContrastingColor: isDark ? Colors.black : Colors.white,
      scaffoldBackgroundColor: c.background,
      barBackgroundColor: isDark
          ? const Color(0xEB10131A)
          : const Color(0xEBF8F6F6),
      textTheme: CupertinoTextThemeData(
        primaryColor: c.primary,
        textStyle: TextStyle(
          inherit: false,
          fontSize: 15,
          height: 1.35,
          color: c.textPrimary,
          decoration: TextDecoration.none,
          fontFamily: '.SF Pro Text',
        ),
        navTitleTextStyle: TextStyle(
          inherit: false,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: c.textPrimary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryLight,
      brightness: Brightness.light,
      primary: primaryLight,
      secondary: streakAmberLight,
      surface: lightColors.background,
    );
    return _baseTheme(colorScheme, lightColors);
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
      primary: primaryDark,
      secondary: streakAmberDark,
      surface: darkColors.background,
    );
    return _baseTheme(colorScheme, darkColors);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme, AppColors c) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      cupertinoOverrideTheme: cupertinoFor(c.brightness),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),
    );
  }
}
