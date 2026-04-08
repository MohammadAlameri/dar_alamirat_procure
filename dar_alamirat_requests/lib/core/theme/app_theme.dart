import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors from web
  static const Color primaryPink = Color(0xFFe4cde7);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color darkGray = Color(0xFF212529);
  static const Color successGreen = Color(0xFF198754);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color dangerRed = Color(0xFFDC3545);
  static const Color white = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 215, 154, 224),
        primary: primaryPink,
        secondary: primaryPink,
        surface: backgroundGray,
        error: dangerRed,
      ),
      scaffoldBackgroundColor: backgroundGray,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: darkGray,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryPink,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: darkGray,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
