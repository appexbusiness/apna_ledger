import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'fin_icons.dart';
import 'motion.dart';

enum ToastType { success, error, info }

extension on ToastType {
  Color get color => switch (this) {
        ToastType.success => AppColors.income,
        ToastType.error => AppColors.expense,
        ToastType.info => AppColors.info,
      };
}

/// Floating toast banners on the root overlay (above sheets and the nav).
///
/// Capture before an async gap, like ScaffoldMessenger:
/// ```dart
/// final toast = Toaster.of(context);
/// await work();
/// toast.success('Saved');
/// ```
class Toaster {
  Toaster._(this._overlay);

  factory Toaster.of(BuildContext context) =>
      Toaster._(Overlay.of(context, rootOverlay: true));

  final OverlayState _overlay;
  static OverlayEntry? _current;

  void success(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    IconData? actionIcon,
  }) =>
      show(
        message,
        type: ToastType.success,
        actionLabel: actionLabel,
        onAction: onAction,
        actionIcon: actionIcon,
      );

  void info(String message) => show(message, type: ToastType.info);

  /// Error toast with an optional retry action.
  void error(String message, {VoidCallback? onRetry, String? retryLabel}) =>
      show(
        message,
        type: ToastType.error,
        actionLabel: onRetry == null ? null : retryLabel,
        onAction: onRetry,
        actionIcon: Icons.refresh_rounded,
      );

  void show(
    String message, {
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? actionIcon,
  }) {
    _current?.remove();
    _current = null;
    switch (type) {
      case ToastType.success:
        AppHaptics.light();
      case ToastType.error:
        AppHaptics.heavy();
      case ToastType.info:
        AppHaptics.select();
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastView(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        actionIcon: actionIcon,
        onGone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    _overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.type,
    required this.onGone,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String message;
  final ToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final VoidCallback onGone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 220),
  )..forward();
  Timer? _timer;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    final hold = widget.type == ToastType.error
        ? const Duration(milliseconds: 4200)
        : const Duration(milliseconds: 2600);
    _timer = Timer(hold, _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onGone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 10;
    final color = widget.type.color;
    final s = Theme.of(context).extension<AppSurfaces>() ?? AppSurfaces.light;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = _c.status == AnimationStatus.reverse
                  ? Curves.easeIn.transform(_c.value)
                  : AppMotion.spring.transform(_c.value);
              return Opacity(
                opacity: _c.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * -80 + _drag),
                  child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
                ),
              );
            },
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragUpdate: (d) =>
                  setState(() => _drag = math.min(0, _drag + d.delta.dy)),
              onVerticalDragEnd: (d) {
                if (_drag < -24 || (d.primaryVelocity ?? 0) < -300) {
                  _dismiss();
                } else {
                  setState(() => _drag = 0);
                }
              },
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: s.glass,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: color.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: AppSurfaces.glow(color, strength: 0.6),
                      ),
                      child: Row(
                        children: [
                          AnimatedStatusIcon(type: widget.type, size: 38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                height: 1.3,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (widget.actionLabel != null &&
                              widget.onAction != null) ...[
                            const SizedBox(width: 8),
                            Pressable(
                              onTap: () {
                                _dismiss();
                                widget.onAction!();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.actionIcon ??
                                          Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.actionLabel!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A drawn status icon: the check / cross strokes itself in, the info
/// badge pulses. Plays once on build.
class AnimatedStatusIcon extends StatefulWidget {
  const AnimatedStatusIcon({
    super.key,
    required this.type,
    this.size = 40,
    this.delay = Duration.zero,
  });

  final ToastType type;
  final double size;
  final Duration delay;

  @override
  State<AnimatedStatusIcon> createState() => _AnimatedStatusIconState();
}

class _AnimatedStatusIconState extends State<AnimatedStatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.type.color;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pop = AppMotion.bouncy.transform(
          (_c.value / 0.45).clamp(0.0, 1.0),
        );
        final stroke = Curves.easeOutCubic.transform(
          ((_c.value - 0.3) / 0.7).clamp(0.0, 1.0),
        );
        final shake = widget.type == ToastType.error
            ? math.sin(stroke * math.pi * 4) * 3 * (1 - stroke)
            : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: 0.4 + 0.6 * pop,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.lighten(color, 0.14), color],
                ),
                boxShadow: AppSurfaces.glow(color, strength: 0.7),
              ),
              child: CustomPaint(
                painter: _StatusPainter(type: widget.type, t: stroke),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPainter extends CustomPainter {
  _StatusPainter({required this.type, required this.t});
  final ToastType type;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.1;

    Path partial(Path p, double f) {
      final out = Path();
      for (final m in p.computeMetrics()) {
        out.addPath(m.extractPath(0, m.length * f), Offset.zero);
      }
      return out;
    }

    switch (type) {
      case ToastType.success:
        final p = Path()
          ..moveTo(w * 0.28, w * 0.52)
          ..lineTo(w * 0.44, w * 0.67)
          ..lineTo(w * 0.72, w * 0.36);
        canvas.drawPath(partial(p, t), paint);
      case ToastType.error:
        final a = Path()
          ..moveTo(w * 0.33, w * 0.33)
          ..lineTo(w * 0.67, w * 0.67);
        final b = Path()
          ..moveTo(w * 0.67, w * 0.33)
          ..lineTo(w * 0.33, w * 0.67);
        canvas.drawPath(partial(a, (t * 2).clamp(0.0, 1.0)), paint);
        canvas.drawPath(partial(b, (t * 2 - 1).clamp(0.0, 1.0)), paint);
      case ToastType.info:
        final fill = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(w / 2, w * 0.3), w * 0.065 * t, fill);
        final p = Path()
          ..moveTo(w / 2, w * 0.45)
          ..lineTo(w / 2, w * 0.72);
        canvas.drawPath(partial(p, t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StatusPainter old) =>
      old.t != t || old.type != type;
}

/// Full-screen celebration for important actions (entry saved, goal
/// reached): a big 3D check pops in while gold coins and confetti burst
/// outward, then everything fades. Non-blocking — safe to pop the current
/// route right after calling.
void showSuccessBurst(BuildContext context, {String? message}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  AppHaptics.medium();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SuccessBurst(
      message: message,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _SuccessBurst extends StatefulWidget {
  const _SuccessBurst({required this.onDone, this.message});
  final VoidCallback onDone;
  final String? message;

  @override
  State<_SuccessBurst> createState() => _SuccessBurstState();
}

class _SuccessBurstState extends State<_SuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _particles = List.generate(26, (i) {
      final angle = (i / 26) * 2 * math.pi + r.nextDouble() * 0.3;
      return _Particle(
        angle: angle,
        distance: 110 + r.nextDouble() * 120,
        size: 8 + r.nextDouble() * 12,
        coin: i % 3 == 0,
        color: AppColors.chart[i % AppColors.chart.length],
        spin: r.nextDouble() * 4 - 2,
      );
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final fadeOut = v < 0.75 ? 1.0 : 1 - (v - 0.75) / 0.25;
          final pop = AppMotion.bouncy.transform((v / 0.35).clamp(0.0, 1.0));
          final burst = Curves.easeOutCubic.transform(
            ((v - 0.08) / 0.6).clamp(0.0, 1.0),
          );
          return Opacity(
            opacity: fadeOut.clamp(0.0, 1.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.18 * pop),
                  ),
                ),
                for (final p in _particles)
                  Transform.translate(
                    offset: Offset(
                      math.cos(p.angle) * p.distance * burst,
                      math.sin(p.angle) * p.distance * burst +
                          (burst * burst) * 60,
                    ),
                    child: Transform.rotate(
                      angle: p.spin * burst * math.pi,
                      child: Opacity(
                        opacity: (1 - burst * 0.6).clamp(0.0, 1.0),
                        child: p.coin
                            ? Coin3D(size: p.size * 1.6, turn: burst * p.spin)
                            : Container(
                                width: p.size,
                                height: p.size * 0.5,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: 0.3 + 0.7 * pop,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AnimatedStatusIcon(
                        type: ToastType.success,
                        size: 96,
                        delay: Duration(milliseconds: 60),
                      ),
                      if (widget.message != null) ...[
                        const SizedBox(height: 16),
                        Material(
                          type: MaterialType.transparency,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.message!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.coin,
    required this.color,
    required this.spin,
  });
  final double angle;
  final double distance;
  final double size;
  final bool coin;
  final Color color;
  final double spin;
}

/// Illustrated empty state: floating 3D composition, title, hint, and an
/// optional call to action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.glyph,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.color,
    this.compact = false,
  });

  final FinGlyph glyph;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: compact ? 16 : 36, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Entrance(
            child: FinIllustration(
              glyph: glyph,
              color: color,
              size: compact ? 130 : 180,
            ),
          ),
          const SizedBox(height: 14),
          Entrance(
            index: 1,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Entrance(
              index: 2,
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.semantic.muted, height: 1.45),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            Entrance(
              index: 3,
              child: AppButton(
                label: actionLabel!,
                icon: Icons.add_rounded,
                expand: false,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Illustrated failure state with a retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry});
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedStatusIcon(type: ToastType.error, size: 72),
            const SizedBox(height: 18),
            Text(
              message ?? l10n.somethingWrong,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              AppButton(
                label: l10n.retry,
                icon: Icons.refresh_rounded,
                expand: false,
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
