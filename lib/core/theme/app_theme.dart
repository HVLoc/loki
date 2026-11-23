import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized iOS/Cupertino-first Light & Dark theme tokens (Soft Red primary).
final class AppTheme {
  AppTheme._();

  static const Color primaryLight = Color(0xFFE55353);
  static const Color primaryDark = Color(0xFFFF7A7A);
  static const Color streakAmberLight = Color(0xFFD97706);
  static const Color streakAmberDark = Color(0xFFFBBF24);

  static CupertinoThemeData cupertinoFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? primaryDark : primaryLight;
    final labelColor = isDark
        ? CupertinoColors.label.darkColor
        : CupertinoColors.label.color;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: primary,
      primaryContrastingColor: isDark ? Colors.black : Colors.white,
      scaffoldBackgroundColor: isDark
          ? CupertinoColors.systemGroupedBackground.darkColor
          : CupertinoColors.systemGroupedBackground.color,
      barBackgroundColor: isDark
          ? const Color(0xE61C1C1E)
          : const Color(0xE6F9F9FB),
      textTheme: CupertinoTextThemeData(
        primaryColor: primary,
        textStyle: TextStyle(
          inherit: false,
          fontSize: 16,
          color: labelColor,
          decoration: TextDecoration.none,
          fontFamily: '.SF Pro Text',
        ),
        navTitleTextStyle: TextStyle(
          inherit: false,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: labelColor,
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
      surface: const Color(0xFFF2F2F7),
    );
    return _baseTheme(colorScheme, Brightness.light);
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
      primary: primaryDark,
      secondary: streakAmberDark,
      surface: const Color(0xFF000000),
    );
    return _baseTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cupertinoOverrideTheme: cupertinoFor(brightness),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
