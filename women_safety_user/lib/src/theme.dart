import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color pink = Color(0xFFFF4D8B); // accent
  static const Color lightPink = Color(0xFFFFE7F3);
  static const Color bg = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: bg,
      primaryColor: pink,
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: pink),
      textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.black87),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightPink.withValues(alpha: 0.12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
