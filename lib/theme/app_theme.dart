import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color accentColor = Color(0xFFBB86FC);
  static const Color lightBackground = Color(0xFFF8F8F8);
  static const Color darkBackground = Color(0xFF121212);
  static const Color lightSurfaceColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: lightSurfaceColor,
    ),
    scaffoldBackgroundColor: lightBackground,
    // Text Theme with Google Fonts
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),
    ),
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0, // Flatter design
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: lightSurfaceColor,
    ),
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0, // Flatter design
      ),
    ),
    // Icon Theme
    iconTheme: const IconThemeData(
      size: 24,
      color: primaryColor,
    ),
    // App Bar Theme
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: lightBackground,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    // Slider Theme
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryColor,
      thumbColor: primaryColor,
      overlayColor: Color(0x296200EE), // primaryColor with opacity
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: darkSurfaceColor,
    ),
    scaffoldBackgroundColor: darkBackground,
    // Text Theme with Google Fonts
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme.copyWith(
            displayLarge: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            displayMedium: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            displaySmall: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5),
            titleLarge:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            titleMedium:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            titleSmall:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            bodyLarge:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            bodyMedium:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            bodySmall:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
    ),
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0, // Flatter design
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: darkSurfaceColor,
    ),
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0, // Flatter design
      ),
    ),
    // Icon Theme
    iconTheme: const IconThemeData(
      size: 24,
      color: accentColor,
    ),
    // App Bar Theme
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: darkBackground,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor.withValues(alpha: 0.3),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    // Slider Theme
    sliderTheme: const SliderThemeData(
      activeTrackColor: accentColor,
      thumbColor: accentColor,
      overlayColor: Color(0x29BB86FC), // accentColor with opacity
    ),
  );
}
