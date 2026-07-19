import 'package:flutter/material.dart';

const Color kNeon = Color(0xFF39FF14);
const Color kBackground = Color(0xFF0B0F14);
const Color kSurface = Color(0xFF121821);
const Color kSurfaceCard = Color(0xFF161F2C);
const Color kMuted = Color(0xFF8A9199);

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackground,
    useMaterial3: true,

    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontFamily: 'monospace'),
    ),

    colorScheme: const ColorScheme.dark(
      primary: kNeon,
      secondary: kNeon,
      surface: kSurface,
      onSurface: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kNeon,
        foregroundColor: kBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kNeon, width: 1.5),
      ),
    ),
  );
}
