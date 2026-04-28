import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.green;
  static const Color accentColor = Colors.lightGreen;
  static const Color textColor = Colors.black87;
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Colors.redAccent;

  // ── Design tokens cho Dark Mode ──
  static const Color _darkSurface = Color(0xFF1A1C1E);
  static const Color _darkCard = Color(0xFF2A2D31);
  static const Color _darkText = Color(0xFFE3E3E3);
  static const Color _darkGreen = Color(0xFF66BB6A);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    hintColor: Colors.grey,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      titleLarge: TextStyle(color: textColor, fontSize: 24.0, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: textColor, fontSize: 18.0, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(color: Colors.grey),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        textStyle: const TextStyle(fontSize: 16.0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        side: const BorderSide(color: primaryColor),
        textStyle: const TextStyle(fontSize: 16.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: errorColor),
      ),
      labelStyle: const TextStyle(color: textColor),
      hintStyle: const TextStyle(color: Colors.grey),
      errorStyle: const TextStyle(color: errorColor),
    ),
    iconTheme: const IconThemeData(color: primaryColor),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.black87,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkGreen,
    hintColor: Colors.grey.shade600,
    scaffoldBackgroundColor: _darkSurface,
    colorScheme: ColorScheme.dark(
      primary: _darkGreen,
      secondary: const Color(0xFF81C784),
      error: Colors.redAccent,
      surface: _darkCard,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: _darkText),
      bodyMedium: const TextStyle(color: _darkText),
      titleLarge: const TextStyle(color: _darkText, fontSize: 24.0, fontWeight: FontWeight.bold),
      titleMedium: const TextStyle(color: _darkText, fontSize: 18.0, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(color: Colors.grey.shade400),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkCard,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        textStyle: const TextStyle(fontSize: 16.0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        side: BorderSide(color: _darkGreen),
        textStyle: const TextStyle(fontSize: 16.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _darkGreen),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      errorStyle: const TextStyle(color: Colors.redAccent),
      filled: true,
      fillColor: _darkCard,
    ),
    iconTheme: IconThemeData(color: _darkGreen),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade800,
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
  );
}