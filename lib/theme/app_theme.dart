// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const primary = Color(0xFFD4A853);      // Golden amber
  static const primaryDark = Color(0xFFB8882E);
  static const primaryLight = Color(0xFFEDC878);
  static const accent = Color(0xFFE8543A);        // Warm red
  static const accentLight = Color(0xFFFF7A5C);

  // Light Theme
  static const lightBg = Color(0xFFFAF7F2);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF5F0E8);
  static const lightText = Color(0xFF1A1208);
  static const lightTextSecondary = Color(0xFF6B5B3E);
  static const lightBorder = Color(0xFFE8DCC8);
  static const lightDivider = Color(0xFFEDE4D3);

  // Dark Theme
  static const darkBg = Color(0xFF0F0C08);
  static const darkSurface = Color(0xFF1C1610);
  static const darkCard = Color(0xFF252018);
  static const darkText = Color(0xFFF5EDD8);
  static const darkTextSecondary = Color(0xFFB8A882);
  static const darkBorder = Color(0xFF3D3320);
  static const darkDivider = Color(0xFF2E2718);

  // Status Colors
  static const success = Color(0xFF4CAF7D);
  static const warning = Color(0xFFF5A623);
  static const error = Color(0xFFE53935);
  static const info = Color(0xFF2196F3);
}

class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.lightText,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26, fontWeight: FontWeight.w700, color: text,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: text,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 18, fontWeight: FontWeight.w600, color: text,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 17, fontWeight: FontWeight.w600, color: text,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: text,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15, color: text, height: 1.6,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 13, color: textSec, height: 1.5,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: text,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.lightText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: textSec, fontSize: 13),
        hintStyle: GoogleFonts.dmSans(color: textSec.withOpacity(0.6), fontSize: 13),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        side: BorderSide(color: border),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightText,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return IconThemeData(color: textSec);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return GoogleFonts.dmSans(fontSize: 11, color: textSec);
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightText,
        contentTextStyle: GoogleFonts.dmSans(color: isDark ? AppColors.darkText : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
