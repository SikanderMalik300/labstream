import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - Minimalist Black & White
  static const Color primaryBlack = Color(0xFF000000);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFF404040);
  static const Color lightGray = Color(0xFFB0B0B0);
  static const Color veryLightGray = Color(0xFFE0E0E0);

  // Accent colors for minimal use
  static const Color accentRed = Color(0xFF333333);
  static const Color accentGreen = Color(0xFF2A2A2A);
  static const Color accentBlue = Color(0xFF252525);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: primaryBlack,
      cardColor: darkGray,
      dividerColor: mediumGray,

      colorScheme: const ColorScheme.dark(
        primary: primaryWhite,
        secondary: lightGray,
        surface: darkGray,
        background: primaryBlack,
        error: Colors.redAccent,
        onPrimary: primaryBlack,
        onSecondary: primaryBlack,
        onSurface: primaryWhite,
        onBackground: primaryWhite,
        onError: primaryWhite,
      ),

      // Typography - Small but readable
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryWhite),
        displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryWhite),
        displaySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryWhite),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryWhite),
        titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryWhite),
        titleMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primaryWhite),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lightGray),
        bodyLarge: TextStyle(fontSize: 13, color: primaryWhite),
        bodyMedium: TextStyle(fontSize: 12, color: lightGray),
        bodySmall: TextStyle(fontSize: 11, color: lightGray),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryWhite),
        labelSmall: TextStyle(fontSize: 10, color: lightGray),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkGray,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryWhite, size: 20),
        titleTextStyle: TextStyle(
          color: primaryWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: darkGray,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: mediumGray, width: 0.5),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryWhite,
          foregroundColor: primaryBlack,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryWhite,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: mediumGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: mediumGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryWhite, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        labelStyle: const TextStyle(fontSize: 12, color: lightGray),
        hintStyle: const TextStyle(fontSize: 12, color: mediumGray),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryWhite,
        size: 18,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: mediumGray,
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}
