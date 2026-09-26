import 'package:flutter/material.dart';

import '../design/motion.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the light (default) and dark [ThemeData]. Layered, soft-3D surfaces
/// with generous radii; every page transition uses the shared depth motion.
class AppTheme {
  AppTheme._();

  static const double radius = 22;
  static const double radiusSm = 16;
  static const double radiusLg = 30;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
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
      surfaces: AppSurfaces.light,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF16A394), // solid teal (no neon)
      onPrimary: Colors.white,
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
      surfaces: AppSurfaces.dark,
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
    required AppSurfaces surfaces,
  }) {
    final textTheme = AppTypography.textTheme(brightness, text, muted);
    final fieldFill = surfaces.surface2;
    OutlineInputBorder outline(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: card,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: DepthPageTransitionsBuilder(),
          TargetPlatform.iOS: DepthPageTransitionsBuilder(),
          TargetPlatform.macOS: DepthPageTransitionsBuilder(),
          TargetPlatform.windows: DepthPageTransitionsBuilder(),
          TargetPlatform.linux: DepthPageTransitionsBuilder(),
          TargetPlatform.fuchsia: DepthPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
        fillColor: fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: muted,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        border: outline(Colors.transparent),
        enabledBorder: outline(Colors.transparent),
        disabledBorder: outline(Colors.transparent),
        focusedBorder: outline(scheme.primary, 1.8),
        errorBorder: outline(AppColors.expense.withValues(alpha: 0.7)),
        focusedErrorBorder: outline(AppColors.expense, 1.8),
        errorStyle: const TextStyle(
          color: AppColors.expense,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaces.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: border),
        ),
        labelStyle: textTheme.bodyMedium,
        side: BorderSide(color: border),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaces.sheet,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surfaces.sheet,
        surfaceTintColor: Colors.transparent,
        dayShape: WidgetStateProperty.all(const CircleBorder()),
        todayBorder: BorderSide(color: scheme.primary, width: 1.4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
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
        surfaces,
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

/// Layered surface tokens for the soft-3D look: card faces, the raised
/// highlight edge, the two-layer shadow, sheets and glass.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.isDark,
    required this.card,
    required this.cardHi,
    required this.surface2,
    required this.sheet,
    required this.edge,
    required this.shadow,
    required this.glass,
  });

  final bool isDark;

  /// Card face (bottom of the face gradient).
  final Color card;

  /// Top of the card face gradient — the "lit" side.
  final Color cardHi;

  /// Recessed surface for fields, segments and chips.
  final Color surface2;

  /// Bottom-sheet background.
  final Color sheet;

  /// 1px highlight along the top edge of raised surfaces.
  final Color edge;

  /// Base shadow colour (alpha applied per layer).
  final Color shadow;

  /// Translucent fill for frosted panels (nav, toasts).
  final Color glass;

  static const light = AppSurfaces(
    isDark: false,
    card: Color(0xFFFFFFFF),
    cardHi: Color(0xFFFFFFFF),
    surface2: AppColors.lightSurface2,
    sheet: Color(0xFFF8F9FD),
    edge: Color(0xFFFFFFFF),
    shadow: Color(0xFF1B2550),
    glass: Color(0xD9FFFFFF),
  );

  static const dark = AppSurfaces(
    isDark: true,
    card: Color(0xFF121932),
    cardHi: Color(0xFF1A2342),
    surface2: AppColors.darkSurface2,
    sheet: Color(0xFF0F1529),
    edge: Color(0x24FFFFFF),
    shadow: Color(0xFF000000),
    glass: Color(0xCC121932),
  );

  /// Two-layer soft shadow: a tight contact shadow plus a wide ambient one.
  List<BoxShadow> elevation([double level = 1]) => [
        BoxShadow(
          color: shadow.withValues(alpha: (isDark ? 0.45 : 0.06) * level),
          blurRadius: 6 * level,
          offset: Offset(0, 2 * level),
        ),
        BoxShadow(
          color: shadow.withValues(alpha: (isDark ? 0.55 : 0.10) * level),
          blurRadius: 28 * level,
          spreadRadius: -4,
          offset: Offset(0, 14 * level),
        ),
      ];

  /// Shadow for coloured objects. Deliberately neutral (not a coloured
  /// glow) so the UI reads as solid colour; [c] is kept for API
  /// compatibility.
  static List<BoxShadow> glow(Color c, {double strength = 1}) => [
        BoxShadow(
          color: const Color(0xFF0B1224).withValues(alpha: 0.16 * strength),
          blurRadius: 14,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF0B1224).withValues(alpha: 0.10 * strength),
          blurRadius: 3,
          offset: const Offset(0, 1.5),
        ),
      ];

  @override
  AppSurfaces copyWith() => this;

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      isDark: t < 0.5 ? isDark : other.isDark,
      card: Color.lerp(card, other.card, t)!,
      cardHi: Color.lerp(cardHi, other.cardHi, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      sheet: Color.lerp(sheet, other.sheet, t)!,
      edge: Color.lerp(edge, other.edge, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
    );
  }
}

extension SemanticColorsX on BuildContext {
  /// Falls back to the app's own tokens when rendered under a foreign theme
  /// (e.g. a bare MaterialApp in tests) instead of crashing.
  AppSemanticColors get semantic {
    final theme = Theme.of(this);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark ? AppTheme.dark : AppTheme.light)
            .extension<AppSemanticColors>()!;
  }

  AppSurfaces get surfaces {
    final theme = Theme.of(this);
    return theme.extension<AppSurfaces>() ??
        (theme.brightness == Brightness.dark
            ? AppSurfaces.dark
            : AppSurfaces.light);
  }
}
