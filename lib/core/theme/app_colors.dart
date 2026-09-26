import 'package:flutter/material.dart';

/// Brand palette — "Midnight Vault": deep navy hero surfaces, an emerald
/// primary, and a minted-gold coin accent. Semantic type colours keep their
/// meaning everywhere (green in, red out, amber lent, purple borrowed).
///
/// Screens should read colours through the theme ([AppTheme] /
/// `context.semantic` / `context.surfaces`); this class is the source.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0E9F8E); // emerald-teal
  static const Color primaryDark = Color(0xFF0B6E66);
  static const Color primaryDeep = Color(0xFF07433F);
  static const Color accent = Color(0xFFF5B82E); // minted gold
  static const Color accentSoft = Color(0xFFFFD56A);
  static const Color goldDeep = Color(0xFFC98A0B);

  // Hero (navy vault) — matches the native splash / launcher background.
  static const Color heroTop = Color(0xFF12304D);
  static const Color heroBottom = Color(0xFF0A1729);
  static const Color heroGlow = Color(0xFF1FD1B9);

  /// Solid (non-neon) in/out colours for text on the navy hero surfaces.
  static const Color onDarkIn = Color(0xFF5CC593);
  static const Color onDarkOut = Color(0xFFF08A8A);

  // Semantics
  static const Color income = Color(0xFF16A34A); // green
  static const Color expense = Color(0xFFEF4444); // red
  static const Color loanGiven = Color(0xFFF0A81C); // amber (requested)
  static const Color loanTaken = Color(0xFF8B5CF6); // purple
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);

  // Light surfaces
  static const Color lightBg = Color(0xFFF3F5FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFECEFF6);
  static const Color lightBorder = Color(0xFFE2E6EF);
  static const Color lightText = Color(0xFF0E1330);
  static const Color lightTextMuted = Color(0xFF6B7390);

  // Dark surfaces
  static const Color darkBg = Color(0xFF070B17);
  static const Color darkSurface = Color(0xFF0E1426);
  static const Color darkCard = Color(0x66141B33);
  static const Color darkCardSolid = Color(0xFF141B31);
  static const Color darkSurface2 = Color(0xFF1A2240);
  static const Color darkBorder = Color(0xFF242D4B);
  static const Color darkText = Color(0xFFEEF1FA);
  static const Color darkTextMuted = Color(0xFF8D96B5);

  /// Category palette used for icons and charts. Deterministic: a category
  /// stores an index into this list for a stable colour.
  static const List<Color> chart = [
    Color(0xFF0E9F8E),
    Color(0xFFE9A20F),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF16A34A),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
  ];

  static Color chartFor(int index) => chart[index % chart.length];

  /// Lighter / darker variants used to build 3D gradients from one base.
  static Color lighten(Color c, [double amount = 0.18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color darken(Color c, [double amount = 0.16]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
