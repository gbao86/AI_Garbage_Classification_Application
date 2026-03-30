import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1B5E20); // Deep Forest Green
  static const Color accentColor = Color(0xFF43A047);  // Vibrant Green
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF4F7F5);
  static const Color cardShadow = Color(0x1A000000);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      onSurface: const Color(0xFF1A1C1E),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      headlineMedium: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      bodyMedium: const TextStyle(color: Color(0xFF44474E), height: 1.5),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1A1C1E),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
      ),
      color: surfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
