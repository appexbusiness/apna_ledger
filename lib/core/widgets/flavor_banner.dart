import 'package:flutter/material.dart';
import '../config/env_config.dart';
import '../config/flavor.dart';

/// Wraps [child] in a corner banner for non-prod builds so QA/UAT are obvious.
class FlavorBanner extends StatelessWidget {
  const FlavorBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final flavor = EnvConfig.instance.flavor;
    if (!flavor.showBanner) return child;
    return Banner(
      message: flavor.label,
      location: BannerLocation.topStart,
      color: Colors.black.withValues(alpha: 0.7),
      child: child,
    );
  }
}
