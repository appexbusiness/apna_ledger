import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography. `Manrope` for clean, geometric body text; `Sora` for display
/// sizes and money figures so balances read bold and confident.
/// Both fall back to the platform font for Indic scripts.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness, Color base, Color muted) {
    final body = GoogleFonts.manropeTextTheme();
    TextStyle? display(TextStyle? s, FontWeight w, double spacing) =>
        GoogleFonts.sora(textStyle: s).copyWith(
          fontWeight: w,
          color: base,
          letterSpacing: spacing,
        );

    return body.copyWith(
      displayLarge: display(body.displayLarge, FontWeight.w800, -1.2),
      displayMedium: display(body.displayMedium, FontWeight.w800, -1),
      displaySmall: display(body.displaySmall, FontWeight.w800, -0.8),
      headlineLarge: display(body.headlineLarge, FontWeight.w800, -0.6),
      headlineMedium: display(body.headlineMedium, FontWeight.w800, -0.5),
      headlineSmall: display(body.headlineSmall, FontWeight.w700, -0.3),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: base,
        letterSpacing: -0.2,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: base,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: base),
      bodyMedium: body.bodyMedium?.copyWith(color: base),
      bodySmall: body.bodySmall?.copyWith(color: muted),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: base,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: muted,
      ),
    );
  }

  /// Money figures (balances, hero amounts). Tabular so rolling digits
  /// don't jitter while they count.
  static TextStyle money({
    double size = 32,
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.sora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.8,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
