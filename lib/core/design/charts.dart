import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

class ChartDatum {
  const ChartDatum({
    required this.label,
    required this.value,
    required this.color,
    this.id,
  });
  final String label;
  final double value;
  final Color color;
  final String? id;
}

/// Cylindrical 3D pillars that grow in with a spring. Tap a pillar to
/// highlight it; [valueLabel] formats the figure shown on top.
class Pillars3D extends StatefulWidget {
  const Pillars3D({
    super.key,
    required this.data,
    required this.valueLabel,
    this.height = 190,
  });

  final List<ChartDatum> data;
  final String Function(double) valueLabel;
  final double height;

  @override
  State<Pillars3D> createState() => _Pillars3DState();
}

class _Pillars3DState extends State<Pillars3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100),)
    ..forward();
  int _selected = -1;

  @override
  void didUpdateWidget(covariant Pillars3D old) {
    super.didUpdateWidget(old);
    final changed = old.data.length != widget.data.length ||
        [
          for (var i = 0; i < widget.data.length; i++)
            old.data[i].value != widget.data[i].value,
        ].any((e) => e);
    if (changed) _c.forward(from: 0.25);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.muted;
    final maxV = widget.data.fold<double>(0, (m, d) => math.max(m, d.value));
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final n = widget.data.length;
          final slot = c.maxWidth / math.max(n, 1);
          return GestureDetector(
            onTapDown: (d) {
              final i = (d.localPosition.dx / slot).floor().clamp(0, n - 1);
              AppHaptics.select();
              setState(() => _selected = _selected == i ? -1 : i);
            },
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                size: Size(c.maxWidth, widget.height),
                painter: _PillarPainter(
                  data: widget.data,
                  max: maxV,
                  t: _c.value,
                  selected: _selected,
                  labelColor: muted,
                  valueColor: Theme.of(context).colorScheme.onSurface,
                  valueLabel: widget.valueLabel,
                  dark: context.surfaces.isDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PillarPainter extends CustomPainter {
  _PillarPainter({
    required this.data,
    required this.max,
    required this.t,
    required this.selected,
    required this.labelColor,
    required this.valueColor,
    required this.valueLabel,
    required this.dark,
  });

  final List<ChartDatum> data;
  final double max;
  final double t;
  final int selected;
  final Color labelColor;
  final Color valueColor;
  final String Function(double) valueLabel;
  final bool dark;

  TextPainter _text(String s, TextStyle style, double maxW) => TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxW);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const labelH = 22.0;
    const valueH = 22.0;
    final slot = size.width / data.length;
    final barW = math.min(slot * 0.46, 46.0);
    final ellH = barW * 0.32;
    final baseY = size.height - labelH - ellH / 2;
    final usable = baseY - valueH - ellH;

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final stagger = ((t - i * 0.08) / 0.8).clamp(0.0, 1.0);
      final grow = AppMotion.spring.transform(stagger);
      final frac = max <= 0 ? 0.0 : d.value / max;
      final h = math.max(ellH * 0.3, usable * frac * grow);
      final cx = slot * i + slot / 2;
      final left = cx - barW / 2;
      final top = baseY - h;
      final sel = i == selected;
      final dim = selected >= 0 && !sel;
      final color = dim ? d.color.withValues(alpha: 0.35) : d.color;

      // Floor shadow.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 4, baseY + 2),
          width: barW * 1.5,
          height: ellH * 1.2,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: dark ? 0.4 : 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Body with cylinder shading.
      final body = Rect.fromLTRB(left, top, left + barW, baseY);
      canvas.drawRect(
        body,
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.darken(color, 0.08),
              AppColors.lighten(color, 0.12),
              color,
              AppColors.darken(color, 0.18),
            ],
            stops: const [0, 0.35, 0.6, 1],
          ).createShader(body),
      );
      // Bottom rounded cap.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, baseY),
          width: barW,
          height: ellH,
        ),
        Paint()..color = AppColors.darken(color, 0.12),
      );
      // Top ellipse (lit).
      final topRect =
          Rect.fromCenter(center: Offset(cx, top), width: barW, height: ellH);
      canvas.drawOval(
        topRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lighten(color, 0.24),
              AppColors.lighten(color, 0.06),
            ],
          ).createShader(topRect),
      );
      if (sel) {
        canvas.drawOval(
          topRect.inflate(3),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: 0.8),
        );
      }

      // Value on top.
      final vt = _text(
        valueLabel(d.value * grow),
        TextStyle(
          color: dim ? labelColor : valueColor,
          fontSize: sel ? 12.5 : 11,
          fontWeight: FontWeight.w800,
        ),
        slot - 4,
      );
      vt.paint(
          canvas, Offset(cx - vt.width / 2, top - ellH / 2 - vt.height - 3),);

      // Label below.
      final lt = _text(
        d.label,
        TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
        ),
        slot - 4,
      );
      lt.paint(canvas, Offset(cx - lt.width / 2, size.height - lt.height));
    }
  }

  @override
  bool shouldRepaint(covariant _PillarPainter old) =>
      old.t != t ||
      old.selected != selected ||
      old.data != data ||
      old.max != max;
}

/// A donut with real thickness: segments are extruded downward, the
/// selected segment lifts out, and the sweep animates in on first build.
/// [center] builds the label shown in the hole (receives the selected
/// index, or -1).
class Donut3D extends StatefulWidget {
  const Donut3D({
    super.key,
    required this.data,
    required this.center,
    this.size = 210,
    this.onSelect,
  });

  final List<ChartDatum> data;
  final Widget Function(int selected) center;
  final double size;
  final ValueChanged<int>? onSelect;

  @override
  State<Donut3D> createState() => _Donut3DState();
}

class _Donut3DState extends State<Donut3D> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),)
    ..forward();
  int _selected = -1;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _hit(Offset p) {
    final size = widget.size;
    // Matches _DonutPainter: centre is lifted by half the extrusion depth.
    final c = Offset(size / 2, size * 0.395);
    final v = p - c;
    // Undo the vertical squash used for the tilt.
    final dy = v.dy / 0.72;
    final r = math.sqrt(v.dx * v.dx + dy * dy);
    final outer = size / 2;
    final inner = outer * 0.56;
    var sel = -1;
    if (r >= inner * 0.9 && r <= outer * 1.1) {
      var a = math.atan2(dy, v.dx) + math.pi / 2;
      if (a < 0) a += 2 * math.pi;
      final total = widget.data.fold<double>(0, (s, d) => s + d.value);
      var acc = 0.0;
      for (var i = 0; i < widget.data.length; i++) {
        acc += widget.data[i].value / total * 2 * math.pi;
        if (a <= acc) {
          sel = i;
          break;
        }
      }
    }
    AppHaptics.select();
    setState(() => _selected = sel == _selected ? -1 : sel);
    widget.onSelect?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTapDown: (d) => _hit(d.localPosition),
      child: SizedBox(
        width: s,
        height: s * 0.86,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                size: Size(s, s * 0.86),
                painter: _DonutPainter(
                  data: widget.data,
                  t: Curves.easeOutCubic.transform(_c.value),
                  selected: _selected,
                  hole: context.surfaces.card,
                  dark: context.surfaces.isDark,
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.08),
              child: SizedBox(
                width: s * 0.42,
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: KeyedSubtree(
                    key: ValueKey(_selected),
                    child: widget.center(_selected),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.data,
    required this.t,
    required this.selected,
    required this.hole,
    required this.dark,
  });

  final List<ChartDatum> data;
  final double t;
  final int selected;
  final Color hole;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (s, d) => s + d.value);
    if (total <= 0) return;
    final w = size.width;
    final depth = w * 0.07;
    final center = Offset(w / 2, size.height / 2 - depth / 2);
    final outer = w / 2 * 0.98;
    final strokeW = outer * 0.44;
    final radius = outer - strokeW / 2;

    // Shadow under the ring.
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, depth + 8),
        width: outer * 2,
        height: outer * 2 * 0.72,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.45 : 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    void ring(double dy, bool top) {
      var start = -math.pi / 2;
      for (var i = 0; i < data.length; i++) {
        final sweep = data[i].value / total * 2 * math.pi * t;
        final mid = start + sweep / 2;
        final lift = i == selected ? 10.0 : 0.0;
        final o = Offset(math.cos(mid) * lift, math.sin(mid) * lift * 0.72);
        canvas.save();
        canvas.translate(center.dx + o.dx, center.dy + dy + o.dy);
        canvas.scale(1, 0.72);
        final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
        final c = data[i].color;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..color = top ? c : AppColors.darken(c, 0.2);
        if (top) {
          paint.shader = SweepGradient(
            startAngle: start,
            endAngle: start + math.max(sweep, 0.001),
            colors: [AppColors.lighten(c, 0.1), c],
          ).createShader(rect);
        }
        canvas.drawArc(rect, start, math.max(sweep - 0.012, 0), false, paint);
        canvas.restore();
        start += sweep;
      }
    }

    // Extrusion: several darker layers, then the lit top face.
    const layers = 6;
    for (var k = layers; k >= 1; k--) {
      ring(depth * k / layers, false);
    }
    ring(0, true);

    // Gloss on the top face.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, 0.72);
    final gloss = Rect.fromCircle(center: Offset.zero, radius: outer);
    canvas.drawArc(
      gloss.deflate(strokeW * 0.15),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 0.18
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.22 * t),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.t != t || old.selected != selected || old.data != data;
}

/// Circular progress with a raised track, gradient sweep and glowing cap.
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value,
    required this.color,
    this.size = 76,
    this.stroke = 9,
    this.child,
  });

  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final track = context.surfaces.surface2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter:
              _RingPainter(v: v, color: color, track: track, stroke: stroke),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.v,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double v;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - stroke / 2 - 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (v <= 0) return;
    final sweep = 2 * math.pi * v;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.max(sweep, 0.01),
          colors: [AppColors.lighten(color, 0.16), color],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
    final end = Offset(
      c.dx + r * math.cos(-math.pi / 2 + sweep),
      c.dy + r * math.sin(-math.pi / 2 + sweep),
    );
    canvas.drawCircle(end, stroke * 0.34, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.v != v || old.color != color || old.track != track;
}

/// A horizontal bar that grows in; optional glow. Used for goals, category
/// shares and type totals.
class GlowBar extends StatelessWidget {
  const GlowBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 10,
    this.delay = Duration.zero,
  });

  final double value;
  final Color color;
  final double height;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: color.withValues(alpha: 0.13),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900) + delay,
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(
                  colors: [AppColors.lighten(color, 0.12), color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two opposing quantities on one bar (given ⟷ taken). Grows from the
/// centre split.
class SplitBar extends StatelessWidget {
  const SplitBar({
    super.key,
    required this.left,
    required this.right,
    required this.leftColor,
    required this.rightColor,
    this.height = 14,
  });

  final double left;
  final double right;
  final Color leftColor;
  final Color rightColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = left + right;
    final frac = total <= 0 ? 0.5 : left / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: frac),
      duration: const Duration(milliseconds: 1000),
      curve: AppMotion.spring,
      builder: (context, f, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              Expanded(
                flex: math.max(1, (f.clamp(0.0, 1.0) * 1000).round()),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.lighten(leftColor, 0.1), leftColor],
                    ),
                  ),
                ),
              ),
              Container(width: 3, color: context.surfaces.card),
              Expanded(
                flex: math.max(1, ((1 - f).clamp(0.0, 1.0) * 1000).round()),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [rightColor, AppColors.lighten(rightColor, 0.1)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
