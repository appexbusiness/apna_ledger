import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/new_txn_args.dart';

/// The signed-in shell: a floating glass navigation pill over the four main
/// tabs, with a raised centre orb that fans out quick actions. Uses
/// go_router's StatefulNavigationShell so each tab keeps its own state.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 240),
  );
  bool _navVisible = true;

  @override
  void initState() {
    super.initState();
    // Rebuild so PopScope knows whether back should close the fan.
    _menu.addStatusListener((_) {
      if (mounted) setState(() {});
    });
  }

  void _goBranch(int index) {
    if (_menu.value > 0) _menu.reverse();
    AppHaptics.select();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _toggleMenu() {
    AppHaptics.medium();
    _menu.isCompleted || _menu.status == AnimationStatus.forward
        ? _menu.reverse()
        : _menu.forward();
  }

  Future<void> _quickAdd(TransactionType type) async {
    await _menu.reverse();
    if (!mounted) return;
    context.push('/dashboard/transaction', extra: NewTxnArgs(type: type));
  }

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final show =
        n.direction != ScrollDirection.reverse || n.metrics.pixels <= 0;
    if (n.direction == ScrollDirection.idle) return false;
    if (show != _navVisible) setState(() => _navVisible = show);
    return false;
  }

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom > 0;
    final visible = _navVisible && !keyboard;

    final items = <_NavSpec>[
      _NavSpec(
        Icons.space_dashboard_outlined,
        Icons.space_dashboard_rounded,
        l10n.dashboard,
      ),
      _NavSpec(
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        l10n.transactions,
      ),
      _NavSpec(Icons.widgets_outlined, Icons.widgets_rounded, l10n.categories),
      _NavSpec(Icons.settings_outlined, Icons.settings_rounded, l10n.settings),
    ];

    return PopScope(
      canPop: _menu.value == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _menu.value > 0) _menu.reverse();
      },
      child: Scaffold(
        extendBody: true,
        // Expand: the closed quick-action layer is a zero-size child, and a
        // loosely-constrained Stack would otherwise shrink to it.
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: widget.navigationShell,
              ),
            ),
            // Quick-action scrim + fan.
            AnimatedBuilder(
              animation: _menu,
              builder: (context, _) {
                if (_menu.value == 0) return const SizedBox.shrink();
                return _QuickActionFan(
                  progress: _menu.value,
                  reversing: _menu.status == AnimationStatus.reverse,
                  bottom: media.padding.bottom + 104,
                  onClose: () => _menu.reverse(),
                  onPick: _quickAdd,
                );
              },
            ),
            // Floating nav.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, 1.6),
                duration: AppMotion.medium,
                curve: visible ? AppMotion.spring : AppMotion.exit,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    math.max(media.padding.bottom, 12) + 4,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _FloatingNav(
                        items: items,
                        current: widget.navigationShell.currentIndex,
                        onTap: _goBranch,
                        menu: _menu,
                        onCenter: _toggleMenu,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.items,
    required this.current,
    required this.onTap,
    required this.menu,
    required this.onCenter,
  });

  final List<_NavSpec> items;
  final int current;
  final ValueChanged<int> onTap;
  final Animation<double> menu;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    const barH = 72.0;
    return SizedBox(
      height: barH + 26,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barH,
            child: GlassPanel(
              radius: 30,
              child: LayoutBuilder(
                builder: (context, c) {
                  // 5 slots: 2 items, centre gap, 2 items.
                  final slot = c.maxWidth / 5;
                  final visual = current < 2 ? current : current + 1;
                  final primary = Theme.of(context).colorScheme.primary;
                  return Stack(
                    children: [
                      // Sliding active indicator.
                      AnimatedPositioned(
                        duration: AppMotion.medium,
                        curve: AppMotion.spring,
                        left: slot * visual + (slot - 54) / 2,
                        top: 8,
                        width: 54,
                        height: 34,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: primary.withValues(alpha: 0.26),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < 2; i++)
                            _NavButton(
                              spec: items[i],
                              selected: current == i,
                              onTap: () => onTap(i),
                            ),
                          const Expanded(child: SizedBox()),
                          for (var i = 2; i < 4; i++)
                            _NavButton(
                              spec: items[i],
                              selected: current == i,
                              onTap: () => onTap(i),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _CenterOrb(menu: menu, onTap: onCenter),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = context.semantic.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: spec.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopOnChange(
                trigger: selected,
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Icon(
                    selected ? spec.activeIcon : spec.icon,
                    key: ValueKey(selected),
                    size: 24,
                    color: selected ? primary : muted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? primary : muted,
                ),
                child: Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised centre action: a glossy emerald orb with a gold ring. Its +
/// rotates into × while the quick-action fan is open.
class _CenterOrb extends StatelessWidget {
  const _CenterOrb({required this.menu, required this.onTap});
  final Animation<double> menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.9,
      semanticLabel: l10n.addTransaction,
      child: AnimatedBuilder(
        animation: menu,
        builder: (context, _) {
          final t = AppMotion.spring.transform(menu.value.clamp(0.0, 1.0));
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
              boxShadow: [
                ...AppSurfaces.glow(AppColors.primary, strength: 1.2),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35 * t),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(AppColors.primary, AppColors.heroTop, t)!,
              ),
              child: Transform.rotate(
                angle: t * math.pi * 0.75,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Blurred scrim with four money actions fanning out in an arc above the
/// centre orb, each arriving on a staggered spring.
class _QuickActionFan extends StatelessWidget {
  const _QuickActionFan({
    required this.progress,
    required this.reversing,
    required this.bottom,
    required this.onClose,
    required this.onPick,
  });

  final double progress;
  final bool reversing;
  final double bottom;
  final VoidCallback onClose;
  final ValueChanged<TransactionType> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <(TransactionType, FinGlyph, String)>[
      (TransactionType.income, FinGlyph.income, l10n.income),
      (TransactionType.expense, FinGlyph.expense, l10n.expense),
      (TransactionType.loanGiven, FinGlyph.given, l10n.loanGiven),
      (TransactionType.loanTaken, FinGlyph.taken, l10n.loanTaken),
    ];
    final width = MediaQuery.of(context).size.width;
    final radius = math.min(150.0, width * 0.36);

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10 * progress,
                  sigmaY: 10 * progress,
                ),
                child: ColoredBox(
                  color:
                      const Color(0xFF050814).withValues(alpha: 0.5 * progress),
                ),
              ),
            ),
          ),
          for (var i = 0; i < actions.length; i++)
            Builder(
              builder: (context) {
                // Spread across 200°→340° (an upward arc).
                final angle =
                    math.pi * (200 + i * (140 / (actions.length - 1))) / 180;
                final local = reversing
                    ? progress
                    : ((progress - i * 0.08) / 0.7).clamp(0.0, 1.0);
                final t = reversing
                    ? Curves.easeIn.transform(local)
                    : AppMotion.bouncy.transform(local);
                final dx = math.cos(angle) * radius * t;
                final dy = math.sin(angle) * radius * 0.8 * t;
                return Positioned(
                  left: width / 2 + dx - 48,
                  bottom: bottom - dy - 20,
                  child: Opacity(
                    opacity: local.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.4 + 0.6 * t.clamp(0.0, 1.2),
                      child: _FanItem(
                        glyph: actions[i].$2,
                        label: actions[i].$3,
                        onTap: () => onPick(actions[i].$1),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FanItem extends StatelessWidget {
  const _FanItem({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  final FinGlyph glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.88,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon3D(glyph: glyph, size: 54),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: glyph.spec.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-fades + slides between shell branches while keeping each branch's
/// navigator alive (state is preserved, only visibility animates).
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: i != currentIndex,
              // The fade/slide must run on this container's tickers, so
              // TickerMode (which pauses the branch's own animations) sits
              // inside them — otherwise an outgoing tab freezes on top.
              child: AnimatedOpacity(
                opacity: i == currentIndex ? 1 : 0,
                duration: AppMotion.medium,
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: i == currentIndex
                      ? Offset.zero
                      : Offset(i < currentIndex ? -0.04 : 0.04, 0),
                  duration: AppMotion.medium,
                  curve: AppMotion.enter,
                  child: AnimatedScale(
                    scale: i == currentIndex ? 1 : 0.98,
                    duration: AppMotion.medium,
                    curve: AppMotion.enter,
                    child: TickerMode(
                      enabled: i == currentIndex,
                      child: children[i],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
