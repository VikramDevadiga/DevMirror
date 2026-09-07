import 'package:flutter/material.dart';

class AppTheme {
  // ── Black & White Monochrome Design System ──

  // Dark Theme (Pitch Black & Pure White)
  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF18181B);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextMuted = Color(0xFFA1A1AA);

  // Light Theme (Clean White & Bold Black)
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightText = Color(0xFF09090B);
  static const Color lightTextMuted = Color(0xFF71717A);

  // Universal Monochromatic Accents
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color liveGreen = Color(0xFF22C55E);
  static const Color primaryCyan = pureWhite;
  static const Color primaryBlue = pureWhite;

  static const String monoFont = 'monospace';

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: pureWhite,
        onPrimary: pureBlack,
        secondary: Color(0xFFE4E4E7),
        surface: darkSurface,
        onSurface: darkText,
        error: Color(0xFFEF4444),
        outline: darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: pureWhite),
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pureWhite, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureWhite,
          foregroundColor: pureBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: darkBorder,
        labelStyle: const TextStyle(
          fontFamily: monoFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: pureWhite,
        ),
        side: const BorderSide(color: darkBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: pureBlack,
        onPrimary: pureWhite,
        secondary: Color(0xFF27272A),
        surface: lightSurface,
        onSurface: lightText,
        error: Color(0xFFDC2626),
        outline: lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: pureBlack),
        titleTextStyle: TextStyle(
          color: pureBlack,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: pureBlack, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        labelStyle: const TextStyle(color: lightTextMuted, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureBlack,
          foregroundColor: pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        selectedColor: lightCard,
        labelStyle: const TextStyle(
          fontFamily: monoFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: pureBlack,
        ),
        side: const BorderSide(color: lightBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
