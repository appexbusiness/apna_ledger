import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the light (default) and dark [ThemeData]. Rounded, airy, premium.
class AppTheme {
  AppTheme._();

  static const double radius = 18;
  static const double radiusSm = 12;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.lightSurface,
      error: AppColors.expense,
    );
    return _base(
      scheme: scheme,
      brightness: Brightness.light,
      bg: AppColors.lightBg,
      card: AppColors.lightCard,
      border: AppColors.lightBorder,
      text: AppColors.lightText,
      muted: AppColors.lightTextMuted,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.accentSoft,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      error: AppColors.expense,
    );
    return _base(
      scheme: scheme,
      brightness: Brightness.dark,
      bg: AppColors.darkBg,
      card: AppColors.darkCardSolid,
      border: AppColors.darkBorder,
      text: AppColors.darkText,
      muted: AppColors.darkTextMuted,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color border,
    required Color text,
    required Color muted,
  }) {
    final textTheme = AppTypography.textTheme(brightness, text, muted);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF1F3F7)
            : const Color(0xFF0E1626),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: text,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFFEFF2F6)
            : const Color(0xFF15203300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: border),
        ),
        labelStyle: textTheme.bodyMedium,
        side: BorderSide(color: border),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: scheme.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: [
        AppSemanticColors(
          income: AppColors.income,
          expense: AppColors.expense,
          loanGiven: AppColors.loanGiven,
          loanTaken: AppColors.loanTaken,
          muted: muted,
          border: border,
        ),
      ],
    );
  }
}

/// Semantic colours exposed via ThemeExtension so widgets can read
/// income/expense colours without importing AppColors directly.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.income,
    required this.expense,
    required this.loanGiven,
    required this.loanTaken,
    required this.muted,
    required this.border,
  });

  final Color income;
  final Color expense;
  final Color loanGiven;
  final Color loanTaken;
  final Color muted;
  final Color border;

  /// Resolve the colour for a transaction-type key ('income', 'expense',
  /// 'loanGiven', 'loanTaken'). Kept as a string so core doesn't depend on the
  /// feature layer.
  Color byTypeKey(String key) {
    switch (key) {
      case 'income':
        return income;
      case 'loanGiven':
        return loanGiven;
      case 'loanTaken':
        return loanTaken;
      case 'expense':
      default:
        return expense;
    }
  }

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? expense,
    Color? loanGiven,
    Color? loanTaken,
    Color? muted,
    Color? border,
  }) =>
      AppSemanticColors(
        income: income ?? this.income,
        expense: expense ?? this.expense,
        loanGiven: loanGiven ?? this.loanGiven,
        loanTaken: loanTaken ?? this.loanTaken,
        muted: muted ?? this.muted,
        border: border ?? this.border,
      );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      loanGiven: Color.lerp(loanGiven, other.loanGiven, t)!,
      loanTaken: Color.lerp(loanTaken, other.loanTaken, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension SemanticColorsX on BuildContext {
  AppSemanticColors get semantic => Theme.of(this).extension<AppSemanticColors>()!;
}
