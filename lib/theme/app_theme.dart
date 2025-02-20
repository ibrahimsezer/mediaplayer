import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orangeAccent,
      brightness: Brightness.light,
      primary: Colors.orangeAccent,
      secondary: Colors.deepOrangeAccent,
      tertiary: Colors.amber,
    ),
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
    ),
    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    // Icon Theme
    iconTheme: const IconThemeData(
      size: 24,
      color: Colors.orangeAccent,
    ),
    // App Bar Theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orangeAccent,
      brightness: Brightness.dark,
      primary: Colors.orangeAccent,
      secondary: Colors.deepOrangeAccent,
      tertiary: Colors.amber,
    ),
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
    ),
    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    // Icon Theme
    iconTheme: const IconThemeData(
      size: 24,
      color: Colors.orangeAccent,
    ),
    // App Bar Theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
}