import 'package:flutter/material.dart';

import '../design/motion.dart';

/// Fades + springs a child in on first build. Kept for existing call sites;
/// delegates to the shared [Entrance] motion.
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child, this.delayMs = 0, this.index = 0});
  final Widget child;
  final int delayMs;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      index: index,
      delay: Duration(milliseconds: delayMs),
      offset: 14,
      child: child,
    );
  }
}
