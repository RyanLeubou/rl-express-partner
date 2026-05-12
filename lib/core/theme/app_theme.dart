import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs RL EXPRESS
  static const Color marineProfond = Color(0xFF0A1628);
  static const Color navyMoyen = Color(0xFF1B3A6B);
  static const Color orSignature = Color(0xFFC9970C);
  static const Color orClair = Color(0xFFF0C040);
  static const Color vertSucces = Color(0xFF1A7A3C);
  static const Color rougeAlerte = Color(0xFF8B1A1A);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color grisClair = Color(0xFFF5F7FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navyMoyen,
        primary: navyMoyen,
        secondary: orSignature,
        error: rougeAlerte,
        surface: blanc,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: marineProfond,
        foregroundColor: blanc,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orSignature,
          foregroundColor: blanc,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grisClair,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navyMoyen, width: 2),
        ),
      ),
    );
  }
}