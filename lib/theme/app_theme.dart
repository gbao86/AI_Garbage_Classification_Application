import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.green;
  static const Color accentColor = Colors.lightGreen;
  static const Color textColor = Colors.black87;
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Colors.redAccent; // Thêm màu lỗi

  static ThemeData lightTheme = ThemeData(
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

// Bạn có thể định nghĩa darkTheme nếu muốn hỗ trợ giao diện tối
// static ThemeData darkTheme = ThemeData(
//   primaryColor: Colors.deepPurple,
//   hintColor: Colors.grey[600],
//   scaffoldBackgroundColor: Colors.grey[900],
//   colorScheme: ColorScheme.dark(
//     primary: Colors.deepPurple,
//     secondary: Colors.purpleAccent,
//     error: Colors.redAccent,
//   ),
//   textTheme: TextTheme(
//     bodyLarge: TextStyle(color: Colors.white),
//     bodyMedium: TextStyle(color: Colors.white),
//     titleLarge: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
//     titleMedium: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w500),
//     bodySmall: TextStyle(color: Colors.grey[400]),
//   ),
//   appBarTheme: AppBarTheme(
//     backgroundColor: Colors.deepPurple,
//     titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
//     iconTheme: const IconThemeData(color: Colors.white),
//   ),
//   elevatedButtonTheme: ElevatedButtonThemeData(
//     style: ElevatedButton.styleFrom(
//       backgroundColor: Colors.purpleAccent,
//       foregroundColor: Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       textStyle: const TextStyle(fontSize: 16.0),
//     ),
//   ),
//   outlinedButtonTheme: OutlinedButtonThemeData(
//     style: OutlinedButton.styleFrom(
//       foregroundColor: Colors.purpleAccent,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       side: BorderSide(color: Colors.purpleAccent),
//       textStyle: const TextStyle(fontSize: 16.0),
//     ),
//   ),
//   inputDecorationTheme: InputDecorationTheme(
//     border: const OutlineInputBorder(),
//     focusedBorder: const OutlineInputBorder(
//       borderSide: BorderSide(color: Colors.purpleAccent),
//     ),
//     errorBorder: const OutlineInputBorder(
//       borderSide: BorderSide(color: Colors.redAccent),
//     ),
//     focusedErrorBorder: const OutlineInputBorder(
//       borderSide: BorderSide(color: Colors.redAccent),
//     ),
//     labelStyle: const TextStyle(color: Colors.white70),
//     hintStyle: TextStyle(color: Colors.grey[600]),
//     errorStyle: const TextStyle(color: Colors.redAccent),
//   ),
//   iconTheme: const IconThemeData(color: Colors.purpleAccent),
//   snackBarTheme: const SnackBarThemeData(
//     backgroundColor: Colors.grey,
//     contentTextStyle: TextStyle(color: Colors.black87),
//   ),
// );
}