import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6C63FF),
        onPrimary: Colors.white,
        secondary: Color(0xFF03DAC6),
        surface: Color(0xFF1E1E2E),
        onSurface: Color(0xFFE0E0E0),
        surfaceContainerHigh: Color(0xFF2A2A3E),
        outline: Color(0xFF44475A),
      ),
      scaffoldBackgroundColor: const Color(0xFF13131F),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFAAAAAA)),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: const Color(0xFF6C63FF),
        backgroundColor: const Color(0xFF2A2A3E),
        labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        side: const BorderSide(color: Color(0xFF44475A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFAAAAAA)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF6C63FF),
        onPrimary: Colors.white,
        secondary: const Color(0xFF018786),
        surface: Colors.white,
        onSurface: Colors.black87,
        surfaceContainerHigh: Colors.grey.shade100,
        outline: Colors.grey.shade300,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.black54),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: const Color(0xFF6C63FF),
        backgroundColor: Colors.white,
        labelStyle: GoogleFonts.inter(color: Colors.black, fontSize: 13),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
      ),
    );
  }
}
