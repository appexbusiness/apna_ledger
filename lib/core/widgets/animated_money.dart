import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// A money amount that "rolls" to a new value and never overflows: it uses
/// compact notation for very large numbers and stays on a single line, scaling
/// down inside any bounded/Flexible parent.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(
    this.value, {
    super.key,
    this.style,
    this.signed = false,
    this.duration = const Duration(milliseconds: 650),
  });

  final double value;
  final TextStyle? style;
  final bool signed;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final text =
            signed ? Formatters.signedSmart(v) : Formatters.moneySmart(v);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, maxLines: 1, softWrap: false, style: style),
        );
      },
    );
  }
}
