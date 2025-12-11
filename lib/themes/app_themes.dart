import 'package:flutter/material.dart';

class AppThemes {
  static const Color primaryBlue = Color(
    0xFF0041c3,
  ); // Biru terang primary
  static const Color lightNavy = Color.fromARGB(
    255,
    56,
    56,
    58,
  ); // NAVY untuk light mode
  static const Color darkNavy = Color.fromARGB(
    255,
    56,
    56,
    58,
  ); // RGB (2,47,86) untuk dark mode

  // =======================
  // LIGHT THEME
  // =======================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.white,

    appBarTheme: AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white, // agar teks/ikon terlihat
      elevation: 0,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryBlue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // =======================
  // DARK THEME
  // =======================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),

    appBarTheme: AppBarTheme(
      backgroundColor: darkNavy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkNavy,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
    ),

    listTileTheme: ListTileThemeData(
      selectedColor: primaryBlue,
      selectedTileColor: primaryBlue.withOpacity(0.1),
    ),

    colorScheme: ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: const Color(0xFF1E1E1E), // Dark surface
      surfaceContainerHighest: const Color(0xFF2A2A2A), // Dark surface variant
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
    ),

    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.white24,
  );
}
