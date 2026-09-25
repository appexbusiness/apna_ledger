import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';

/// Hero card: the animated total net balance on the navy vault panel, with
/// floating coins, this month's in/out, and a gentle 3D tilt that follows
/// the finger.
class BalanceCard extends StatefulWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    this.onInfo,
    this.monthIn = 0,
    this.monthOut = 0,
  });

  final double balance;
  final VoidCallback? onInfo;

  /// This month's money in (income + taken) and out (spending + given).
  final double monthIn;
  final double monthOut;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  Offset _tilt = Offset.zero;

  void _move(Offset local, Size size) {
    final dx = (local.dx / size.width - 0.5).clamp(-0.5, 0.5);
    final dy = (local.dy / size.height - 0.5).clamp(-0.5, 0.5);
    setState(() => _tilt = Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, 200);
        // Raw pointer events: tilt without competing with list scrolling.
        return Listener(
          onPointerDown: (e) => _move(e.localPosition, size),
          onPointerMove: (e) => _move(e.localPosition, size),
          onPointerUp: (_) => setState(() => _tilt = Offset.zero),
          onPointerCancel: (_) => setState(() => _tilt = Offset.zero),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: _tilt),
            duration: AppMotion.medium,
            curve: AppMotion.spring,
            builder: (context, t, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(-t.dy * 0.12)
                ..rotateY(t.dx * 0.12),
              child: child,
            ),
            child: HeroPanel(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    right: -6,
                    top: 10,
                    child: FloatingCoins(scale: 0.9),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      l10n.netBalance,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (widget.onInfo != null)
                            IconOrb(
                              icon: Icons.info_outline_rounded,
                              size: 28,
                              onDark: true,
                              tooltip: l10n.netBalanceHow,
                              onTap: widget.onInfo,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(right: 96),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CountUp(
                            value: widget.balance,
                            format: Formatters.moneyWhole,
                            style: AppTypography.money(
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppConstants.slogan}  ·  ${AppConstants.hashtag}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _FlowPill(
                              icon: Icons.south_west_rounded,
                              label: l10n.thisMonth,
                              value: widget.monthIn,
                              color: const Color(0xFF6EE7A8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FlowPill(
                              icon: Icons.north_east_rounded,
                              label: l10n.thisMonth,
                              value: widget.monthOut,
                              color: const Color(0xFFFF9C9C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlowPill extends StatelessWidget {
  const _FlowPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUp(
                    value: value,
                    format: Formatters.moneySmart,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
