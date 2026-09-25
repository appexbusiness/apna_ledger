import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, gold, danger, secondary, ghost }

/// A pushable 3D button: the face sits on a darker "extrusion" and sinks
/// into it while pressed. Built-in loading state and a short debounce so
/// rapid double-taps never fire the action twice.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.debounce = const Duration(milliseconds: 700),
    this.variant = AppButtonVariant.primary,
    this.color,
    this.expand = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Duration debounce;
  final AppButtonVariant variant;

  /// Overrides the face colour (e.g. tint Save with the transaction type).
  final Color? color;
  final bool expand;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _locked = false;
  bool _down = false;

  bool get _disabled =>
      widget.loading || _locked || widget.onPressed == null;

  void _handleTap() {
    if (_disabled) return;
    AppHaptics.light();
    setState(() => _locked = true);
    widget.onPressed!.call();
    Future.delayed(widget.debounce, () {
      if (mounted) setState(() => _locked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = context.surfaces;
    final v = widget.variant;

    final Color base = widget.color ??
        switch (v) {
          AppButtonVariant.primary => AppColors.primary,
          AppButtonVariant.gold => AppColors.accent,
          AppButtonVariant.danger => AppColors.expense,
          AppButtonVariant.secondary => s.card,
          AppButtonVariant.ghost => Colors.transparent,
        };
    final solid = v == AppButtonVariant.primary ||
        v == AppButtonVariant.gold ||
        v == AppButtonVariant.danger ||
        widget.color != null;
    final Color fg = solid
        ? (v == AppButtonVariant.gold && widget.color == null
            ? const Color(0xFF3A2600)
            : Colors.white)
        : (v == AppButtonVariant.ghost ? scheme.primary : scheme.onSurface);

    final depth = v == AppButtonVariant.ghost ? 0.0 : 5.0;
    final pressed = _down && !_disabled;
    final face = widget.height - depth;

    final content = AnimatedSwitcher(
      duration: AppMotion.fast,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: a, child: child),
      ),
      child: widget.loading
          ? _LoadingDots(key: const ValueKey('loading'), color: fg)
          : Row(
              key: const ValueKey('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
    );

    final button = Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: _disabled ? null : _handleTap,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: widget.onPressed == null ? 0.5 : 1,
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                if (depth > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: face,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: solid
                            ? AppColors.darken(base, 0.16)
                            : context.semantic.border,
                        boxShadow: solid && !pressed
                            ? AppSurfaces.glow(base, strength: 0.8)
                            : null,
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: pressed ? AppMotion.tap : AppMotion.medium,
                  curve: pressed ? Curves.easeOut : AppMotion.bouncy,
                  left: 0,
                  right: 0,
                  top: pressed ? depth : 0,
                  height: face,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: solid
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.lighten(base, 0.08), base],
                            )
                          : (v == AppButtonVariant.secondary
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [s.cardHi, s.card],
                                )
                              : null),
                      border: v == AppButtonVariant.secondary
                          ? Border.all(color: context.semantic.border)
                          : null,
                    ),
                    foregroundDecoration: solid
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.expand) return SizedBox(width: double.infinity, child: button);
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140),
        child: button,
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots({super.key, required this.color});
  final Color color;

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(
                  0,
                  -5 *
                      math.max(
                        0,
                        math.sin((_c.value - i * 0.16) * 2 * math.pi),
                      ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
