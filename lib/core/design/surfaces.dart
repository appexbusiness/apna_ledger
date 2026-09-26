import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// A raised card: solid face, hairline border and a soft two-layer shadow.
/// Pass [tint] for a solid coloured card.
class Surface3D extends StatelessWidget {
  const Surface3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppTheme.radius,
    this.tint,
    this.onTap,
    this.onLongPress,
    this.elevation = 1,
    this.margin,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double elevation;
  final EdgeInsetsGeometry? margin;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    final t = tint;
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: t ?? s.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevation <= 0 ? null : s.elevation(elevation),
        border: border
            ? Border.all(
                color: t != null
                    ? AppColors.darken(t, 0.06)
                    : (s.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : context.semantic.border.withValues(alpha: 0.8)),
              )
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null || onLongPress != null) {
      card = Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        pressedScale: 0.975,
        child: card,
      );
    }
    return card;
  }
}

/// A border painted with a gradient (Flutter's [Border] is single-colour).
/// Used for the lit top edge of raised surfaces.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1});
  final Gradient gradient;
  final double width;

  @override
  BorderSide get top => BorderSide.none;
  @override
  BorderSide get bottom => BorderSide.none;
  @override
  bool get isUniform => true;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final inset = rect.deflate(width / 2);
    if (shape == BoxShape.circle) {
      canvas.drawCircle(inset.center, inset.shortestSide / 2, paint);
    } else if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(inset), paint);
    } else {
      canvas.drawRect(inset, paint);
    }
  }
}

/// The solid navy "vault" panel used for hero moments (balance, auth, lock,
/// splash), with a faint dotted texture.
class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 30,
    this.glow = AppColors.heroGlow,
    this.accentGlow = AppColors.accent,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color glow;
  final Color accentGlow;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: AppColors.heroBottom.withValues(alpha: 0.45),
            blurRadius: 34,
            spreadRadius: -8,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: CustomPaint(
          painter: _HeroPainter(glow: glow, accent: accentGlow),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: br,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.glow, required this.accent});
  final Color glow;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Solid navy — no glows and no diagonal light beam.
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.heroTop);

    // Fine dotted grid, very faint.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (double x = 14; x < size.width; x += 22) {
      for (double y = 14; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), 0.9, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) =>
      old.glow != glow || old.accent != accent;
}

/// Frosted glass panel — blur + translucent fill + hairline highlight.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.blur = 22,
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: s.elevation(1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? s.glass,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: s.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Page background. [tint]/[secondary] are kept for call-site compatibility.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.tint = AppColors.primary,
    this.secondary = AppColors.accent,
  });

  final Widget child;
  final Color tint;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    // Solid page colour (the old ambient glows were removed on purpose).
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

/// Circular icon button with a raised face — used in headers and toolbars.
class IconOrb extends StatelessWidget {
  const IconOrb({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.size = 44,
    this.onDark = false,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool onDark;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    final fg = color ??
        (onDark ? Colors.white : Theme.of(context).colorScheme.onSurface);
    final orb = Pressable(
      onTap: busy ? null : onTap,
      semanticLabel: tooltip,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onDark ? Colors.white.withValues(alpha: 0.12) : s.card,
          boxShadow: onDark ? null : s.elevation(0.6),
          border: Border.all(
            color: onDark
                ? Colors.white.withValues(alpha: 0.16)
                : context.semantic.border.withValues(alpha: 0.6),
          ),
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  height: size * 0.4,
                  width: size * 0.4,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Icon(icon, size: size * 0.46, color: fg),
        ),
      ),
    );
    return tooltip == null ? orb : Tooltip(message: tooltip, child: orb);
  }
}

/// Large screen header: optional back orb, big title + subtitle, and
/// trailing actions. Tab screens and pushed pages share it.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 8),
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            IconOrb(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall?.copyWith(fontSize: 24),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.semantic.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 8), a],
        ],
      ),
    );
  }
}

/// A segmented control whose selected pill slides between options with a
/// spring. Generic over the option value.
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.labels,
    this.icons,
    this.color,
    this.height = 46,
  });

  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T)? labels;
  final IconData Function(T)? icons;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    final accent = color ?? Theme.of(context).colorScheme.primary;
    final index = math.max(0, options.indexOf(value));
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: s.surface2,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.medium,
                curve: AppMotion.spring,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    color: s.card,
                    boxShadow: s.elevation(0.35),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (o == value) return;
                          AppHaptics.select();
                          onChanged(o);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppMotion.fast,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: o == value
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color:
                                  o == value ? accent : context.semantic.muted,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icons != null) ...[
                                  Icon(
                                    icons!(o),
                                    size: 16,
                                    color: o == value
                                        ? accent
                                        : context.semantic.muted,
                                  ),
                                  if (labels != null) const SizedBox(width: 6),
                                ],
                                if (labels != null)
                                  Flexible(
                                    child: Text(
                                      labels!(o),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Selectable pill chip with an animated fill and a pop on selection.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final s = context.surfaces;
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.select();
              onTap!();
            },
      haptic: false,
      pressedScale: 0.93,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:
              selected ? c.withValues(alpha: s.isDark ? 0.22 : 0.13) : s.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? c : context.semantic.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: selected
                  ? Padding(
                      key: const ValueKey('on'),
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.check_rounded, size: 15, color: c),
                    )
                  : (icon != null
                      ? Padding(
                          key: const ValueKey('icon'),
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(icon, size: 15, color: c),
                        )
                      : const SizedBox.shrink(key: ValueKey('off'))),
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? c : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label above a group of settings/fields.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key, this.padding});
  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.semantic.muted,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
