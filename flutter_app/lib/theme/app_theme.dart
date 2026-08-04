import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores
  static const Color bgDeep = Color(0xFF08080F);
  static const Color bgCard = Color(0xFF12121E);
  static const Color bgSurface = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFF9D5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9090B0);
  static const Color divider = Color(0xFF2A2A40);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: pink,
          surface: bgSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          labelSmall: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
        ),
        dividerColor: divider,
        useMaterial3: true,
      );
}
