import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Logging-streak banner: a flickering 3D flame and a 7-day ember track.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.days});
  final int days;

  static const _flame = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Surface3D(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const _Flicker(child: Icon3D(glyph: FinGlyph.streak, size: 50)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.streakBanner(days),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.streakSubtitle,
                  style: TextStyle(
                    color: context.semantic.muted,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Entrance(
                          index: i,
                          offset: 6,
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: i < days
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFFB347), _flame],
                                    )
                                  : null,
                              color:
                                  i < days ? null : context.surfaces.surface2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Flicker extends StatefulWidget {
  const _Flicker({required this.child});
  final Widget child;

  @override
  State<_Flicker> createState() => _FlickerState();
}

class _FlickerState extends State<_Flicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
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
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scaleY: 1 + 0.06 * _c.value,
        scaleX: 1 - 0.02 * _c.value,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    );
  }
}
