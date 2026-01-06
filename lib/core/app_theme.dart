import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color voltGreen = Color(0xFFCCFF00);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color surfaceGrey = Color(0xFF121212);
  static const double minTouchTarget = 60.0;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: voltGreen,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: surfaceGrey,
      textTheme: GoogleFonts.oswaldTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: voltGreen,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: voltGreen,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: voltGreen,
          foregroundColor: backgroundBlack,
          minimumSize: const Size(double.infinity, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: voltGreen,
          side: const BorderSide(color: voltGreen, width: 2),
          minimumSize: const Size(double.infinity, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surfaceGrey,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: voltGreen, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: voltGreen, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        labelStyle: TextStyle(color: voltGreen),
      ),
    );
  }
}
