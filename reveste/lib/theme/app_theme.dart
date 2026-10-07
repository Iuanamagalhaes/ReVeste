import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const verde = Color(0xFF355E4B);
  static const creme = Color(0xFFF7F2E8);
  static const terracota = Color(0xFFC96F4A);
  static const salvia = Color(0xFFA9BFAF);
  static const grafite = Color(0xFF22352D);
  static const branco = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.verde,
        primary: AppColors.verde,
        secondary: AppColors.terracota,
        surface: AppColors.creme,
      ),
    );
    final t = base.textTheme
        .apply(bodyColor: AppColors.grafite, displayColor: AppColors.grafite);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.creme,
      textTheme: t.copyWith(
        bodyLarge: GoogleFonts.inter(textStyle: t.bodyLarge),
        bodyMedium: GoogleFonts.inter(textStyle: t.bodyMedium),
        bodySmall: GoogleFonts.inter(textStyle: t.bodySmall),
        labelLarge: GoogleFonts.inter(textStyle: t.labelLarge),
        headlineMedium: GoogleFonts.fraunces(
            fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.grafite),
        titleLarge: GoogleFonts.fraunces(
            fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.grafite),
        titleMedium: GoogleFonts.fraunces(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grafite),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: AppColors.branco,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verde,
          side: const BorderSide(color: AppColors.verde),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.branco,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.salvia),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.salvia),
        ),
      ),
    );
  }
}