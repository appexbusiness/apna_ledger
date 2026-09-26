import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/motion.dart';
import '../services/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Slides in when the device goes offline, explaining that entries are saved
/// locally and will sync when back online.
class InternetBanner extends ConsumerWidget {
  const InternetBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(connectivityProvider).value ?? true;

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.spring,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: online
          ? const SizedBox(width: double.infinity, key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const _PulsingIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.internetNeeded,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.warning.withValues(alpha: 0.2 + 0.15 * _c.value),
                  ),
        child: child,
      ),
      child: const Icon(
        Icons.cloud_off_rounded,
        color: AppColors.warning,
        size: 19,
      ),
    );
  }
}
