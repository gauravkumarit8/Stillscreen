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
