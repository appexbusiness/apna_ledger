import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// The app's visual vocabulary. Every concept maps to a glyph + a base
/// colour, and money concepts carry a small ₹ coin badge so "income",
/// "spending", "given" and "taken" read as money at a glance.
enum FinGlyph {
  income,
  expense,
  given,
  taken,
  wallet,
  bank,
  upi,
  cash,
  categories,
  notes,
  reminders,
  recurring,
  analytics,
  goals,
  profile,
  settings,
  calculator,
  download,
  security,
  lock,
  fingerprint,
  pin,
  key,
  language,
  theme,
  help,
  share,
  legal,
  privacy,
  info,
  search,
  calendar,
  person,
  interest,
  logout,
  streak,
  history,
  edit,
  delete,
  learn,
  email,
  phone,
  filter,
  success,
  error,
}

class FinGlyphSpec {
  const FinGlyphSpec(this.icon, this.color, {this.coin = false});
  final IconData icon;
  final Color color;

  /// Show the ₹ coin badge (money-movement concepts).
  final bool coin;
}

extension FinGlyphX on FinGlyph {
  FinGlyphSpec get spec {
    switch (this) {
      case FinGlyph.income:
        return const FinGlyphSpec(
          Icons.south_west_rounded,
          AppColors.income,
          coin: true,
        );
      case FinGlyph.expense:
        return const FinGlyphSpec(
          Icons.north_east_rounded,
          AppColors.expense,
          coin: true,
        );
      case FinGlyph.given:
        return const FinGlyphSpec(
          Icons.outbox_rounded,
          AppColors.loanGiven,
          coin: true,
        );
      case FinGlyph.taken:
        return const FinGlyphSpec(
          Icons.move_to_inbox_rounded,
          AppColors.loanTaken,
          coin: true,
        );
      case FinGlyph.wallet:
        return const FinGlyphSpec(
          Icons.account_balance_wallet_rounded,
          AppColors.primary,
        );
      case FinGlyph.bank:
        return const FinGlyphSpec(
          Icons.account_balance_rounded,
          Color(0xFF3B82F6),
        );
      case FinGlyph.upi:
        return const FinGlyphSpec(Icons.qr_code_2_rounded, Color(0xFF7C3AED));
      case FinGlyph.cash:
        return const FinGlyphSpec(Icons.payments_rounded, AppColors.income);
      case FinGlyph.categories:
        return const FinGlyphSpec(Icons.widgets_rounded, Color(0xFF06B6D4));
      case FinGlyph.notes:
        return const FinGlyphSpec(
          Icons.sticky_note_2_rounded,
          Color(0xFFE9A20F),
        );
      case FinGlyph.reminders:
        return const FinGlyphSpec(
          Icons.notifications_active_rounded,
          Color(0xFFF97316),
        );
      case FinGlyph.recurring:
        return const FinGlyphSpec(
          Icons.event_repeat_rounded,
          AppColors.loanTaken,
        );
      case FinGlyph.analytics:
        return const FinGlyphSpec(Icons.insights_rounded, Color(0xFF3B82F6));
      case FinGlyph.goals:
        return const FinGlyphSpec(Icons.savings_rounded, Color(0xFFEC4899));
      case FinGlyph.profile:
        return const FinGlyphSpec(Icons.person_rounded, AppColors.primary);
      case FinGlyph.settings:
        return const FinGlyphSpec(Icons.settings_rounded, Color(0xFF64748B));
      case FinGlyph.calculator:
        return const FinGlyphSpec(Icons.calculate_rounded, Color(0xFF0EA5E9));
      case FinGlyph.download:
        return const FinGlyphSpec(Icons.download_rounded, AppColors.primary);
      case FinGlyph.security:
        return const FinGlyphSpec(Icons.shield_rounded, Color(0xFF0E9F8E));
      case FinGlyph.lock:
        return const FinGlyphSpec(Icons.lock_rounded, Color(0xFF0E9F8E));
      case FinGlyph.fingerprint:
        return const FinGlyphSpec(
          Icons.fingerprint_rounded,
          Color(0xFF0E9F8E),
        );
      case FinGlyph.pin:
        return const FinGlyphSpec(Icons.pin_rounded, Color(0xFF3B82F6));
      case FinGlyph.key:
        return const FinGlyphSpec(Icons.key_rounded, Color(0xFFE9A20F));
      case FinGlyph.language:
        return const FinGlyphSpec(Icons.translate_rounded, Color(0xFF3B82F6));
      case FinGlyph.theme:
        return const FinGlyphSpec(Icons.palette_rounded, Color(0xFFEC4899));
      case FinGlyph.help:
        return const FinGlyphSpec(
          Icons.support_agent_rounded,
          Color(0xFF0EA5E9),
        );
      case FinGlyph.share:
        return const FinGlyphSpec(Icons.ios_share_rounded, AppColors.income);
      case FinGlyph.legal:
        return const FinGlyphSpec(Icons.gavel_rounded, Color(0xFF64748B));
      case FinGlyph.privacy:
        return const FinGlyphSpec(
          Icons.privacy_tip_rounded,
          Color(0xFF0E9F8E),
        );
      case FinGlyph.info:
        return const FinGlyphSpec(Icons.info_rounded, Color(0xFF3B82F6));
      case FinGlyph.search:
        return const FinGlyphSpec(Icons.search_rounded, Color(0xFF64748B));
      case FinGlyph.calendar:
        return const FinGlyphSpec(
          Icons.calendar_month_rounded,
          Color(0xFF3B82F6),
        );
      case FinGlyph.person:
        return const FinGlyphSpec(Icons.person_rounded, AppColors.loanGiven);
      case FinGlyph.interest:
        return const FinGlyphSpec(Icons.percent_rounded, Color(0xFFF97316));
      case FinGlyph.logout:
        return const FinGlyphSpec(Icons.logout_rounded, AppColors.expense);
      case FinGlyph.streak:
        return const FinGlyphSpec(
          Icons.local_fire_department_rounded,
          Color(0xFFF97316),
        );
      case FinGlyph.history:
        return const FinGlyphSpec(Icons.history_rounded, Color(0xFF64748B));
      case FinGlyph.edit:
        return const FinGlyphSpec(Icons.edit_rounded, AppColors.primary);
      case FinGlyph.delete:
        return const FinGlyphSpec(
          Icons.delete_outline_rounded,
          AppColors.expense,
        );
      case FinGlyph.learn:
        return const FinGlyphSpec(Icons.school_rounded, Color(0xFF7C3AED));
      case FinGlyph.email:
        return const FinGlyphSpec(Icons.mail_rounded, Color(0xFF3B82F6));
      case FinGlyph.phone:
        return const FinGlyphSpec(
          Icons.phone_iphone_rounded,
          AppColors.primary,
        );
      case FinGlyph.filter:
        return const FinGlyphSpec(Icons.tune_rounded, AppColors.primary);
      case FinGlyph.success:
        return const FinGlyphSpec(Icons.check_rounded, AppColors.income);
      case FinGlyph.error:
        return const FinGlyphSpec(Icons.close_rounded, AppColors.expense);
    }
  }
}

enum Icon3DStyle {
  /// Solid extruded tile: solid face on a darker side (the thickness).
  solid,

  /// Soft tinted tile with a coloured glyph — for dense lists.
  soft,
}

/// A dimensional icon tile. Use [glyph] for the shared vocabulary, or pass
/// [icon] + [color] for data-driven icons (e.g. category icons).
class Icon3D extends StatelessWidget {
  const Icon3D({
    super.key,
    this.glyph,
    this.icon,
    this.color,
    this.size = 48,
    this.style = Icon3DStyle.solid,
    this.coin,
  }) : assert(glyph != null || icon != null);

  final FinGlyph? glyph;
  final IconData? icon;
  final Color? color;
  final double size;
  final Icon3DStyle style;

  /// Override the coin badge (defaults to the glyph's spec).
  final bool? coin;

  @override
  Widget build(BuildContext context) {
    final spec = glyph?.spec;
    final base = color ?? spec?.color ?? Theme.of(context).colorScheme.primary;
    final data = icon ?? spec!.icon;
    final showCoin = coin ?? spec?.coin ?? false;
    final r = size * 0.32;
    final dark = context.surfaces.isDark;

    final Widget tile;
    if (style == Icon3DStyle.solid) {
      final depth = size * 0.07;
      tile = SizedBox(
        width: size,
        height: size + depth,
        child: Stack(
          children: [
            // Extruded side (the block's thickness).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.darken(base, 0.2),
                  borderRadius: BorderRadius.circular(r),
                  boxShadow: AppSurfaces.glow(base, strength: 0.9),
                ),
              ),
            ),
            // Face.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  color: base,
                ),
                child: Center(
                  child: Icon(
                    data,
                    size: size * 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color:
                            AppColors.darken(base, 0.25).withValues(alpha: 0.6),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      tile = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          color: base.withValues(alpha: dark ? 0.22 : 0.12),
          border: Border.all(color: base.withValues(alpha: dark ? 0.35 : 0.2)),
        ),
        child: Center(
          child: Icon(data, size: size * 0.5, color: base),
        ),
      );
    }

    if (!showCoin) return tile;
    return SizedBox(
      width: size + size * 0.14,
      height: size + size * 0.14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: 0, child: tile),
          Positioned(
            right: 0,
            bottom: style == Icon3DStyle.solid ? -size * 0.04 : 0,
            child: Coin3D(size: size * 0.42),
          ),
        ],
      ),
    );
  }
}

/// A painted gold ₹ coin. [turn] (0..1) rotates it about its vertical axis
/// with visible edge thickness; use [SpinningCoin] for the animated version.
class Coin3D extends StatelessWidget {
  const Coin3D({super.key, this.size = 56, this.turn = 0, this.symbol = '₹'});
  final double size;
  final double turn;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CoinPainter(turn: turn, symbol: symbol),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({required this.turn, required this.symbol});
  final double turn;
  final String symbol;

  static const _rimDark = Color(0xFFB9780A);
  static const _rimLight = Color(0xFFFFE08A);
  static const _faceA = Color(0xFFFFD35A);
  static const _faceB = Color(0xFFF2A516);
  static const _edge = Color(0xFFC98A0B);

  @override
  void paint(Canvas canvas, Size size) {
    final a = turn * 2 * math.pi;
    final sx = math.cos(a);
    final w = size.width * math.max(sx.abs(), 0.08);
    final h = size.height;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final thickness = size.width * 0.09 * math.sin(a).abs();
    final dir = math.sin(a) >= 0 ? 1.0 : -1.0;

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.98),
        width: size.width * 0.7,
        height: h * 0.1,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Edge band (thickness) — stacked ellipses shifted sideways.
    final steps = (thickness).ceil().clamp(0, 12);
    for (var i = steps; i > 0; i--) {
      final dx = dir * i * (thickness / math.max(steps, 1));
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + dx, cy), width: w, height: h * 0.96,),
        Paint()..color = _edge,
      );
    }

    final faceRect =
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h * 0.96);
    // Rim.
    canvas.drawOval(
      faceRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_rimLight, _rimDark],
        ).createShader(faceRect),
    );
    // Face.
    final inner = Rect.fromCenter(
      center: faceRect.center,
      width: faceRect.width * 0.8,
      height: faceRect.height * 0.8,
    );
    canvas.drawOval(
      inner,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [_faceA, _faceB],
        ).createShader(inner),
    );
    // Inner ring groove.
    canvas.drawOval(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.018
        ..color = _rimDark.withValues(alpha: 0.55),
    );

    // Embossed symbol (dark offset + light highlight), squashed with the turn.
    if (sx.abs() > 0.25) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(sx.abs(), 1);
      void glyph(Color c, Offset o) {
        final tp = TextPainter(
          text: TextSpan(
            text: symbol,
            style: TextStyle(
              fontSize: size.height * 0.46,
              fontWeight: FontWeight.w900,
              color: c,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2) + o);
      }

      glyph(_rimDark.withValues(alpha: 0.9), const Offset(0.8, 1.4));
      glyph(const Color(0xFFFFF4C9), const Offset(-0.5, -0.6));
      glyph(const Color(0xFFE39B0C), Offset.zero);
      canvas.restore();
    }

    // Specular highlight.
    final spec = Rect.fromCenter(
      center: Offset(cx - w * 0.16, cy - h * 0.2),
      width: w * 0.5,
      height: h * 0.26,
    );
    canvas.drawOval(
      spec,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(spec),
    );
  }

  @override
  bool shouldRepaint(covariant _CoinPainter old) =>
      old.turn != turn || old.symbol != symbol;
}

/// A coin that spins continuously (or once, with [loop] false), with an
/// optional gentle float.
class SpinningCoin extends StatefulWidget {
  const SpinningCoin({
    super.key,
    this.size = 72,
    this.period = const Duration(milliseconds: 3600),
    this.loop = true,
  });
  final double size;
  final Duration period;
  final bool loop;

  @override
  State<SpinningCoin> createState() => _SpinningCoinState();
}

class _SpinningCoinState extends State<SpinningCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating && !_c.isCompleted) {
      widget.loop ? _c.repeat() : _c.forward();
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
      builder: (context, _) {
        // Ease the spin so it lingers face-on, then flips quickly.
        final t = Curves.easeInOutCubic.transform(_c.value);
        return Coin3D(size: widget.size, turn: t);
      },
    );
  }
}

/// A small cluster of floating coins — decoration for hero panels.
class FloatingCoins extends StatelessWidget {
  const FloatingCoins({super.key, this.scale = 1});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120 * scale,
      height: 110 * scale,
      child: Stack(
        children: [
          Positioned(
            right: 6 * scale,
            top: 0,
            child: Floating(
              amplitude: 5,
              phase: 0.2,
              child: SpinningCoin(size: 58 * scale),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 8 * scale,
            child: Floating(
              amplitude: 4,
              phase: 0.6,
              period: const Duration(milliseconds: 2800),
              child: Coin3D(size: 36 * scale, turn: 0.07),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Floating(
              amplitude: 3,
              phase: 0.9,
              child: Coin3D(size: 26 * scale, turn: 0.93),
            ),
          ),
        ],
      ),
    );
  }
}

/// A composed 3D illustration: a tilted back plate, a floating tinted card,
/// the main extruded icon, orbiting coins and sparkles. Used for empty,
/// success and onboarding moments.
class FinIllustration extends StatelessWidget {
  const FinIllustration({
    super.key,
    required this.glyph,
    this.color,
    this.size = 170,
    this.coins = true,
  });

  final FinGlyph glyph;
  final Color? color;
  final double size;
  final bool coins;

  @override
  Widget build(BuildContext context) {
    final c = color ?? glyph.spec.color;
    final dark = context.surfaces.isDark;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo.
          Container(
            width: size * 0.95,
            height: size * 0.95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: dark ? 0.12 : 0.08),
            ),
          ),
          // Back plate.
          Transform.rotate(
            angle: -0.22,
            child: Container(
              width: size * 0.56,
              height: size * 0.44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.1),
                color: c.withValues(alpha: dark ? 0.22 : 0.14),
                border: Border.all(color: c.withValues(alpha: 0.25)),
              ),
            ),
          ),
          // Mid card with fake content lines.
          Floating(
            amplitude: 3,
            phase: 0.5,
            tilt: 0.02,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: size * 0.56,
                height: size * 0.4,
                padding: EdgeInsets.all(size * 0.05),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.09),
                  color: context.surfaces.card,
                  boxShadow: context.surfaces.elevation(0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _line(c, size * 0.24, 0.5),
                    SizedBox(height: size * 0.025),
                    _line(c, size * 0.16, 0.25),
                  ],
                ),
              ),
            ),
          ),
          // Main object.
          Positioned(
            left: size * 0.16,
            top: size * 0.18,
            child: Floating(
              amplitude: 6,
              child: Icon3D(glyph: glyph, color: c, size: size * 0.38),
            ),
          ),
          if (coins) ...[
            Positioned(
              right: size * 0.08,
              top: size * 0.1,
              child: Floating(
                amplitude: 5,
                phase: 0.3,
                child: SpinningCoin(size: size * 0.2),
              ),
            ),
            Positioned(
              right: size * 0.2,
              bottom: size * 0.1,
              child: Floating(
                amplitude: 4,
                phase: 0.75,
                child: Coin3D(size: size * 0.13, turn: 0.9),
              ),
            ),
          ],
          Positioned(
            left: size * 0.1,
            bottom: size * 0.2,
            child: _Sparkle(color: c, size: size * 0.07),
          ),
          Positioned(
            right: size * 0.05,
            top: size * 0.45,
            child: _Sparkle(color: AppColors.accent, size: size * 0.05),
          ),
        ],
      ),
    );
  }

  Widget _line(Color c, double w, double a) => Container(
        width: w,
        height: 5,
        decoration: BoxDecoration(
          color: c.withValues(alpha: a),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _Sparkle extends StatefulWidget {
  const _Sparkle({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  State<_Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<_Sparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(_c),
      child: ScaleTransition(
        scale: Tween(begin: 0.7, end: 1.1).animate(_c),
        child: Icon(
          Icons.auto_awesome_rounded,
          size: widget.size,
          color: widget.color,
        ),
      ),
    );
  }
}
