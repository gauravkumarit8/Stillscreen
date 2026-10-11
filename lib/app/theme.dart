import 'package:flutter/material.dart';

// Palette: mist (background), deep water (text, primary), still teal (accent),
// pebble (borders).
const mist = Color(0xFFEAF0F1);
const deepWater = Color(0xFF14323A);
const stillTeal = Color(0xFF2E7D7A);
const pebble = Color(0xFFB9C7CB);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: stillTeal,
    brightness: Brightness.light,
  ).copyWith(
    primary: deepWater,
    onPrimary: Colors.white,
    secondary: stillTeal,
    surface: mist,
    onSurface: deepWater,
    outline: pebble,
    outlineVariant: pebble,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: mist,
    appBarTheme: const AppBarTheme(
      backgroundColor: mist,
      foregroundColor: deepWater,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

// Dark palette: the same teal on a deep background.
const _darkBg = Color(0xFF0F2329);
const _darkText = Color(0xFFE3ECEE);
const _tealOnDark = Color(0xFF62B5B0);

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: stillTeal,
    brightness: Brightness.dark,
  ).copyWith(
    primary: _tealOnDark,
    onPrimary: _darkBg,
    secondary: _tealOnDark,
    surface: _darkBg,
    onSurface: _darkText,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBg,
      foregroundColor: _darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

extension StillColors on BuildContext {
  /// Card borders and tracks, following the light or dark theme.
  Color get line => Theme.of(this).colorScheme.outlineVariant;
}
