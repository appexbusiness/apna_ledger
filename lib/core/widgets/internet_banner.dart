import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// An animated banner that slides in when the device goes offline, explaining
/// that entries are saved locally and will sync when back online.
class InternetBanner extends ConsumerWidget {
  const InternetBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(connectivityProvider).value ?? true;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: online
          ? const SizedBox(width: double.infinity, key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const _PulsingIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.internetNeeded,
                        style: const TextStyle(fontSize: 12.5, height: 1.3)),
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
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: const Icon(Icons.wifi_off_rounded,
          color: AppColors.warning, size: 20),
    );
  }
}
