import 'package:flutter/material.dart';

/// Animated branded header used across auth screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Image.asset('assets/branding/logo_512.png',
              height: 68, width: 68),
        ),
        const SizedBox(height: 20),
        Text(title, style: text.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!,
              style: text.bodyMedium?.copyWith(color: context.mutedColor)),
        ],
      ],
    );
  }
}

extension on BuildContext {
  Color get mutedColor =>
      Theme.of(this).textTheme.bodySmall?.color ?? Colors.grey;
}
