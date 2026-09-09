import 'package:flutter/material.dart';

/// Açık (gündüz) tema — Material 3, teal ton.
ThemeData buildTheme() => _build(ThemeMode.light);

/// Karanlık (gece) tema.
ThemeData buildDarkTheme() => _build(ThemeMode.dark);

ThemeData _build(ThemeMode mod) {
  final karanlik = mod == ThemeMode.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00897B),
    brightness: karanlik ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
