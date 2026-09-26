import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'motion.dart';

/// The Apna Ledger mark (transparent wallet + calculator art), brought to
/// life: a softly breathing solid halo behind it, a gentle float, a soft floor
/// shadow. (No light-sweep effect, by design.)
class BrandLogo extends StatefulWidget {
  const BrandLogo({
    super.key,
    this.size = 96,
    this.animate = true,
    this.halo = true,
    this.haloColor = AppColors.heroGlow,
  });

  final double size;

  /// Float + shine + halo pulse. Turn off for tiny inline uses.
  final bool animate;
  final bool halo;
  final Color haloColor;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || reduceMotion(context)) {
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
    final s = widget.size;
    final image = Image.asset(
      AppConstants.logoAsset,
      width: s,
      height: s,
      cacheWidth: (s * MediaQuery.devicePixelRatioOf(context)).round(),
      filterQuality: FilterQuality.medium,
    );
    if (!widget.animate) {
      return SizedBox(width: s, height: s, child: image);
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final wave = math.sin(t * 2 * math.pi);
        return SizedBox(
          width: s * 1.3,
          height: s * 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.halo)
                Container(
                  width: s * (1.15 + 0.06 * wave),
                  height: s * (1.15 + 0.06 * wave),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.haloColor.withValues(alpha: 0.14 + 0.04 * wave),
                  ),
                ),
              // Floor shadow shrinks as the logo rises.
              Positioned(
                bottom: s * 0.08,
                child: Container(
                  width: s * (0.62 - 0.05 * wave),
                  height: s * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s),
                    color: Colors.black.withValues(alpha: 0.22 - 0.05 * wave),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: s * 0.08,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -s * 0.04 * (wave + 1) / 2),
                child: Transform.rotate(
                  angle: wave * 0.025,
                  child: image,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The Appex Business mark on a light chip, so its navy "A" stays visible
/// on dark and navy surfaces.
class AppexMark extends StatelessWidget {
  const AppexMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset(AppConstants.appexLogoAsset),
    );
  }
}

/// "Track it. Don't guess it" + the #Rakhe Pai Pai Ka Hisaab hashtag chip.
class BrandSlogan extends StatelessWidget {
  const BrandSlogan({
    super.key,
    this.onDark = true,
    this.center = true,
    this.compact = false,
  });

  final bool onDark;
  final bool center;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = onDark
        ? Colors.white.withValues(alpha: 0.85)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          AppConstants.slogan,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12.5 : 14,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.accent.withValues(alpha: onDark ? 0.18 : 0.12),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            AppConstants.hashtag,
            style: TextStyle(
              color: onDark ? AppColors.accentSoft : AppColors.goldDeep,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 12.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
