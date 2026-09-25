import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../settings/presentation/security_providers.dart';

/// Branded splash, choreographed in beats on the navy vault:
///   1. the Apna Ledger mark flips in with a glow and coins,
///   2. "Apna Ledger" reveals letter by letter,
///   3. the slogan and #hashtag chip rise in,
///   4. a feature carousel cycles,
///   5. the Appex Business co-brand settles at the bottom.
/// Then it routes onward (lock / dashboard / login via redirects).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Drives beats 1–3 and 5 (0 → 1 over the intro).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  int _feature = 0;
  late final _timer = Stream<int>.periodic(
    const Duration(milliseconds: 1100),
    (i) => i,
  ).listen((i) {
    if (mounted) setState(() => _feature = i);
  });

  static const _features = [
    (FinGlyph.income, 'One-tap entries', 'Log income & spending instantly'),
    (FinGlyph.analytics, 'Clear insights', 'See where your money goes'),
    (FinGlyph.given, 'Money given & taken', 'Track loans with people'),
    (FinGlyph.security, 'Private & secure', 'No bank details, only your hisaab'),
  ];

  @override
  void initState() {
    super.initState();
    _timer; // start the carousel
    Future.delayed(const Duration(milliseconds: 3600), _go);
  }

  void _go() {
    if (!mounted) return;
    final loggedIn = ref.read(authControllerProvider) != null;
    final locked = ref.read(appLockProvider) || ref.read(pinProvider);
    context.go(loggedIn && locked ? '/lock' : '/dashboard');
  }

  @override
  void dispose() {
    _timer.cancel();
    _intro.dispose();
    super.dispose();
  }

  /// Progress of a beat that runs between [from] and [to] of the intro.
  double _beat(double from, double to, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_intro.value - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final f = _features[_feature % _features.length];
    return Scaffold(
      body: HeroPanel(
        radius: 0,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, _) {
              final logo = _beat(0, 0.45, AppMotion.bouncy);
              final flip = _beat(0, 0.45);
              final brand = _beat(0.35, 1);
              return SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    // Beat 1 — the mark.
                    Opacity(
                      opacity: _beat(0, 0.25),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0015)
                          ..rotateY((1 - flip) * 1.4)
                          ..scaleByDouble(
                            0.5 + 0.5 * logo,
                            0.5 + 0.5 * logo,
                            1,
                            1,
                          ),
                        child: SizedBox(
                          width: 230,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              const BrandLogo(
                                size: 150,
                                haloColor: AppColors.accent,
                              ),
                              Positioned(
                                right: 0,
                                top: 8,
                                child: Opacity(
                                  opacity: _beat(0.3, 0.55),
                                  child: const Floating(
                                    phase: 0.4,
                                    child: SpinningCoin(size: 40),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 6,
                                bottom: 26,
                                child: Opacity(
                                  opacity: _beat(0.4, 0.65),
                                  child: const Floating(
                                    phase: 0.8,
                                    amplitude: 4,
                                    child: Coin3D(size: 26, turn: 0.08),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Beat 2 — the name, letter by letter.
                    _LetterReveal(
                      text: AppConstants.appName,
                      progress: brand,
                    ),
                    const SizedBox(height: 12),
                    // Beat 3 — slogan + hashtag.
                    Opacity(
                      opacity: _beat(0.6, 0.85),
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - _beat(0.6, 0.85))),
                        child: const BrandSlogan(),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Beat 4 — feature carousel.
                    Opacity(
                      opacity: _beat(0.75, 1),
                      child: SizedBox(
                        height: 118,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: AppMotion.spring,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.25),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: FittedBox(
                            key: ValueKey(_feature),
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon3D(glyph: f.$1, size: 46, coin: false),
                                const SizedBox(height: 10),
                                Text(
                                  f.$2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  f.$3,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _features.length; i++)
                          AnimatedContainer(
                            duration: AppMotion.medium,
                            curve: AppMotion.emphasized,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: (i == _feature % _features.length) ? 22 : 6,
                            decoration: BoxDecoration(
                              color: (i == _feature % _features.length)
                                  ? AppColors.accentSoft
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(flex: 2),
                    // Beat 5 — parent-company co-brand.
                    Opacity(
                      opacity: _beat(0.7, 1),
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _beat(0.7, 1))),
                        child: const _AppexCoBrand(),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Reveals [text] one letter at a time, each rising with a small bounce.
class _LetterReveal extends StatelessWidget {
  const _LetterReveal({required this.text, required this.progress});
  final String text;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontSize: 32,
        );
    final n = text.length;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < n; i++)
            Builder(
              builder: (context) {
                final start = i / (n + 4);
                final t = AppMotion.bouncy.transform(
                  ((progress - start) / 0.3).clamp(0.0, 1.0),
                );
                return Opacity(
                  opacity: math.min(1, t.clamp(0.0, 1.0) * 1.2),
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - t)),
                    child: Text(text[i], style: style),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AppexCoBrand extends StatelessWidget {
  const _AppexCoBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppexMark(size: 38),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A product of',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Appex Business',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
