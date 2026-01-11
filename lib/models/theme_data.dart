import 'package:flutter/material.dart';

class PurrsonaTheme {
  static const Color primaryBackground = Color(0xFFFAF8F5);
  static const Color secondaryBackground = Color(0xFFF3EFF0);
  static const Color accentPeach = Color(0xFFE8A89B);
  static const Color accentCoral = Color(0xFFD4746B);
  static const Color accentSoft = Color(0xFFB8A3A3);
  static const Color textDark = Color(0xFF3D3D3D);
  static const Color textMuted = Color(0xFF7B7B7B);
  static const Color accentGold = Color(0xFFC9A961);

  static final ThemeData beautifulTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: accentCoral,
    scaffoldBackgroundColor: primaryBackground,

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: accentCoral,
      onPrimary: Colors.white,
      secondary: accentPeach,
      onSecondary: textDark,
      surface: Colors.white,
      onSurface: textDark,
      error: Colors.red,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textDark),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: textDark,
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: textMuted,
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: textDark,
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: textDark,
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentCoral,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentCoral,
        side: const BorderSide(color: accentCoral, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}