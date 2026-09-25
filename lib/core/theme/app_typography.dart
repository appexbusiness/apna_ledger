import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography. `Manrope` for a clean, premium, geometric feel.
/// Falls back to the platform default if fonts can't be fetched.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness, Color base, Color muted) {
    final theme = GoogleFonts.manropeTextTheme();
    return theme.copyWith(
      displaySmall: theme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: base,
        letterSpacing: -0.5,
      ),
      headlineMedium: theme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: base,
        letterSpacing: -0.4,
      ),
      headlineSmall: theme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleLarge: theme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleMedium: theme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: base,
      ),
      bodyLarge: theme.bodyLarge?.copyWith(color: base),
      bodyMedium: theme.bodyMedium?.copyWith(color: base),
      bodySmall: theme.bodySmall?.copyWith(color: muted),
      labelLarge: theme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: base,
      ),
    );
  }
}
