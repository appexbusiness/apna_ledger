import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sweeping shimmer highlight over its child's shape. Wrap skeleton boxes.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    final base = s.surface2;
    final hi = s.isDark ? const Color(0xFF2A3458) : Colors.white;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, hi, base],
          stops: const [0.25, 0.5, 0.75],
          transform: _Slide(_c.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.t);
  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.surfaces.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder ledger rows shown while entries stream in.
class LedgerSkeleton extends StatelessWidget {
  const LedgerSkeleton({super.key, this.rows = 6});
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          const Row(
            children: [
              SkeletonBox(width: 90, height: 12),
              Spacer(),
              SkeletonBox(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  const SkeletonBox(width: 46, height: 46, radius: 15),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120.0 + (i % 3) * 30, height: 13),
                        const SizedBox(height: 8),
                        const SkeletonBox(width: 90, height: 10),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 70, height: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
