import 'package:flutter/material.dart';

/// Brand palette. Deep emerald + gold accent reads as "money / premium".
/// Every colour used in the UI resolves through the ThemeData built in
/// [AppTheme] — screens must never hard-code raw Color values.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0F766E); // deep teal-emerald
  static const Color primaryDark = Color(0xFF115E59);
  static const Color accent = Color(0xFFD4A017); // muted gold
  static const Color accentSoft = Color(0xFFF2C94C);

  // Semantics
  static const Color income = Color(0xFF15803D); // dark green
  static const Color expense = Color(0xFFE5484D); // red
  static const Color loanGiven = Color(0xFFF0A81C); // amber (requested)
  static const Color loanTaken = Color(0xFF8B5CF6); // purple
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);

  // Light surfaces
  static const Color lightBg = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8EBF0);
  static const Color lightText = Color(0xFF0B1220);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Dark surfaces
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF121A2A);
  static const Color darkCard = Color(0xFF16203440);
  static const Color darkCardSolid = Color(0xFF162034);
  static const Color darkBorder = Color(0xFF233145);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  /// A soft category palette used for pie / bar charts. Deterministic:
  /// index a category into this list for a stable colour.
  static const List<Color> chart = [
    Color(0xFF0F766E),
    Color(0xFFD4A017),
    Color(0xFF3B82F6),
    Color(0xFFE5484D),
    Color(0xFF8B5CF6),
    Color(0xFF12A150),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
  ];

  static Color chartFor(int index) => chart[index % chart.length];
}
