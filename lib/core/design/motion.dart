import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Motion tokens shared by every animated surface, so the whole app moves
/// with one "physics": quick press feedback, springy arrivals, calm exits.
class AppMotion {
  AppMotion._();

  static const Duration tap = Duration(milliseconds: 110);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 360);
  static const Duration slow = Duration(milliseconds: 620);
  static const Duration count = Duration(milliseconds: 900);

  /// Overshoots ~6% then settles — a soft spring without a physics sim.
  static const Curve spring = Cubic(0.2, 1.3, 0.35, 1);

  /// Stronger bounce for small, playful objects (icons, badges, the FAB).
  static const Curve bouncy = Cubic(0.34, 1.56, 0.64, 1);

  /// Snappy with no overshoot — for anything that animates size, colour,
  /// borders or shadows (AnimatedContainer / AnimatedSize), where
  /// extrapolating past the target produces invalid values.
  static const Curve emphasized = Cubic(0.2, 0.9, 0.1, 1);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// True when the user asked the OS to reduce motion. Looping, purely
/// decorative animations (floating, spinning, sparkles) stop when set.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Light-touch haptics. Kept tiny and consistent: selection ticks for
/// toggles/tabs, a light impact for primary presses, heavy for destructive.
class AppHaptics {
  AppHaptics._();
  static void select() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
}

/// Page transition for every pushed route: the new page rises slightly and
/// scales up from 96% while fading in; the page underneath recedes a touch.
/// Reads as depth (layers stacking) rather than a flat slide.
class DepthPageTransitionsBuilder extends PageTransitionsBuilder {
  const DepthPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    final behind = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOut,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([enter, behind]),
      child: child,
      builder: (context, child) {
        final t = enter.value;
        final b = behind.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 28),
            child: Transform.scale(
              scale: (0.96 + 0.04 * t) * (1 - 0.03 * b),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Wraps any child with press-depth feedback: it sinks to [pressedScale]
/// while held, springs back on release, and fires a light haptic on tap.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.haptic = true,
    this.semanticLabel,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _active =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _set(bool v) {
    if (!_active || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: _active,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: _active && widget.onTap != null
            ? () {
                if (widget.haptic) AppHaptics.light();
                widget.onTap!();
              }
            : null,
        onLongPress: _active && widget.onLongPress != null
            ? () {
                AppHaptics.medium();
                widget.onLongPress!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.pressedScale : 1,
          duration: _down ? AppMotion.tap : AppMotion.medium,
          curve: _down ? Curves.easeOut : AppMotion.bouncy,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.5,
            duration: AppMotion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Card-entrance animation: fades, rises and settles with a spring. Pass an
/// [index] to stagger siblings (each step is ~55ms, capped so long lists
/// don't wait).
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.offset = 22,
    this.scaleFrom = 0.97,
    this.duration = AppMotion.slow,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final double offset;
  final double scaleFrom;
  final Duration duration;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: AppMotion.spring);

  @override
  void initState() {
    super.initState();
    final stagger = Duration(milliseconds: math.min(widget.index, 8) * 55);
    final wait = widget.delay + stagger;
    if (wait == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(wait, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Animated number that counts from its previous value to [value] using
/// [format]. Starts from zero on first build for the "balance reveal".
class CountUp extends StatefulWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = AppMotion.count,
    this.textAlign,
  });

  final double value;
  final String Function(double v) format;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  double _from = 0;

  @override
  void didUpdateWidget(covariant CountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween(begin: _from, end: widget.value),
      duration: widget.duration,
      curve: Curves.easeOutExpo,
      builder: (context, v, _) => Text(
        widget.format(v),
        maxLines: 1,
        softWrap: false,
        textAlign: widget.textAlign,
        style: widget.style,
      ),
    );
  }
}

/// Gently bobs its child up and down (and optionally tilts) forever —
/// used for floating 3D objects so compositions feel alive, not busy.
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.period = const Duration(milliseconds: 3200),
    this.phase = 0,
    this.tilt = 0.03,
  });

  final Widget child;
  final double amplitude;
  final Duration period;

  /// 0..1 — offsets the cycle so several floating items don't move in sync.
  final double phase;
  final double tilt;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final a = (_c.value + widget.phase) * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, math.sin(a) * widget.amplitude),
          child: Transform.rotate(
            angle: math.cos(a) * widget.tilt,
            child: child,
          ),
        );
      },
    );
  }
}

/// Shakes horizontally whenever [trigger] changes — the "no" gesture used
/// for wrong PINs and failed validation.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void didUpdateWidget(covariant Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      AppHaptics.heavy();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Pops its child in with a bouncy scale whenever [trigger] changes —
/// used for selection changes on icons and badges.
class PopOnChange extends StatefulWidget {
  const PopOnChange({super.key, required this.trigger, required this.child});
  final Object? trigger;
  final Widget child;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant PopOnChange old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = AppMotion.bouncy.transform(_c.value);
        return Transform.scale(scale: 0.7 + 0.3 * t, child: child);
      },
    );
  }
}
