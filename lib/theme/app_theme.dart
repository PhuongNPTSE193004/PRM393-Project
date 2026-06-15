import 'package:flutter/material.dart';

const Color kNeon = Color(0xFF39FF14);
const Color kBackground = Color(0xFF0B0F14);
const Color kSurface = Color(0xFF121821);
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
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kNeon, width: 1),
      ),
    ),
  );
}
