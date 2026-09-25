import 'package:flutter/material.dart';

import '../design/brand.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';

/// "Powered by Appex Business" with a tappable website link. Apna Ledger is the
/// product; Appex Business is the parent company.
class PoweredByAppex extends StatelessWidget {
  const PoweredByAppex({super.key, this.center = true, this.onDark = false});
  final bool center;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final muted =
        onDark ? Colors.white.withValues(alpha: 0.7) : context.semantic.muted;
    final link = onDark ? Colors.white : Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        const AppexMark(size: 36),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Powered by Appex Business',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: () => openUrl(appexWebsite),
                child: Text(
                  'www.appexbusiness.com',
                  style: TextStyle(
                    color: link,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
