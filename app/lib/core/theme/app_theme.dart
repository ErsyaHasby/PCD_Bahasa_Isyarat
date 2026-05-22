import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Warna Utama ───────────────────────────────────────────────────────
  static const Color primary    = Color(0xFF0D47A1);   // Dark Blue
  static const Color secondary  = Color(0xFF29B6F6);   // Light Blue
  static const Color success    = Color(0xFF22D3A5);
  static const Color warning    = Color(0xFFFFB347);
  static const Color error      = Color(0xFFFF6B6B);

  static const Color bg         = Color(0xFFF8FAFC);   // Off white / Light gray
  static const Color surface    = Color(0xFFFFFFFF);   // White
  static const Color card       = Color(0xFFFFFFFF);
  static const Color divider    = Color(0xFFE2E8F0);

  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint      = Color(0xFF94A3B8);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cameraOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)], // Keep dark for camera readability
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Light Theme ───────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16, color: textSecondary),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14, color: textSecondary),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary, size: 22),
      dividerColor: divider,
      splashColor: primary.withOpacity(0.1),
      highlightColor: primary.withOpacity(0.05),
    );
  }
}
