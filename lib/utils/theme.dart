// import 'package:flutter/material.dart';

// class AppTheme {
//   // Primary Colors
//   static const Color mainColor = Color(0xFF007BFF);    // Bright Blue
//   static const Color backgroundColor = Color(0xFF121212); // Deep Black
//   static const Color cardBackground = Color(0xFF1E1E1E);  // Dark Grey
//   static const Color textColor = Color(0xFFFFFFFF);      // Pure White
//   static const Color buttonColor = Color(0xFFFF3B30);    // Emergency Red

//   // Secondary Colors
//   static const Color successColor = Color(0xFF28A745);   // Green
//   static const Color warningColor = Color(0xFFFFC107);   // Yellow
//   static const Color errorColor = Color(0xFFDC3545);     // Red
//   static const Color disabledColor = Color(0xFF6C757D);  // Grey

//   static ThemeData darkTheme = ThemeData(
//     // Base Theme
//     brightness: Brightness.dark,
//     scaffoldBackgroundColor: backgroundColor,
//     primaryColor: mainColor,

//     // AppBar Theme
//     appBarTheme: const AppBarTheme(
//       backgroundColor: backgroundColor,
//       foregroundColor: textColor,
//       elevation: 0,
//     ),

//     // Card Theme
//     cardTheme: const CardTheme(
//       color: cardBackground,
//       elevation: 4,
//       margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//     ),

//     // Text Theme
//     textTheme: const TextTheme(
//       displayLarge: TextStyle(color: textColor),
//       displayMedium: TextStyle(color: textColor),
//       displaySmall: TextStyle(color: textColor),
//       headlineMedium: TextStyle(color: textColor),
//       headlineSmall: TextStyle(color: textColor),
//       titleLarge: TextStyle(color: textColor),
//       bodyLarge: TextStyle(color: textColor),
//       bodyMedium: TextStyle(color: textColor),
//       bodySmall: TextStyle(color: textColor),
//     ),

//     // Button Theme
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: buttonColor,
//         foregroundColor: textColor,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     ),

//     // Floating Action Button Theme
//     floatingActionButtonTheme: const FloatingActionButtonThemeData(
//       backgroundColor: buttonColor,
//       foregroundColor: textColor,
//     ),

//     // Icon Theme
//     iconTheme: const IconThemeData(
//       color: textColor,
//     ),

//     // Input Decoration Theme
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: cardBackground,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: mainColor),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: mainColor),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: mainColor, width: 2),
//       ),
//       labelStyle: const TextStyle(color: textColor),
//       hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
//     ),

//     // Bottom Navigation Bar Theme
//     bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//       backgroundColor: backgroundColor,
//       selectedItemColor: mainColor,
//       unselectedItemColor: disabledColor,
//     ),

//     // Dialog Theme
//     dialogTheme: DialogTheme(
//       backgroundColor: cardBackground,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//     ),

//     // Snackbar Theme
//     snackBarTheme: const SnackBarThemeData(
//       backgroundColor: cardBackground,
//       contentTextStyle: TextStyle(color: textColor),
//       actionTextColor: mainColor,
//     ),
//   );
// }

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color mainColor = Color(0xFF007BFF); // Bright Blue
  static const Color backgroundColor = Color(0xFF121212); // Deep Black
  static const Color cardBackground = Color(0xFF1E1E1E); // Dark Grey
  static const Color textColor = Color(0xFFFFFFFF); // Pure White
  static const Color buttonColor = Color(0xFFFF3B30); // Emergency Red

  // Secondary Colors
  static const Color successColor = Color(0xFF28A745); // Green
  static const Color warningColor = Color(0xFFFFC107); // Yellow
  static const Color errorColor = Color(0xFFDC3545); // Red
  static const Color disabledColor = Color(0xFF6C757D); // Grey

  static ThemeData darkTheme = ThemeData(
    // Base Theme
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: mainColor,

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      // Removed 'const'
      color: cardBackground,
      elevation: 4,
      margin: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 16), // Added 'const' here
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textColor),
      displayMedium: TextStyle(color: textColor),
      displaySmall: TextStyle(color: textColor),
      headlineMedium: TextStyle(color: textColor),
      headlineSmall: TextStyle(color: textColor),
      titleLarge: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      bodySmall: TextStyle(color: textColor),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: buttonColor,
      foregroundColor: textColor,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: textColor,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: mainColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: mainColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: mainColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textColor),
      hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: mainColor,
      unselectedItemColor: disabledColor,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      // Removed 'const'
      backgroundColor: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Snackbar Theme
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: cardBackground,
      contentTextStyle: TextStyle(color: textColor),
      actionTextColor: mainColor,
    ),
  );
}
