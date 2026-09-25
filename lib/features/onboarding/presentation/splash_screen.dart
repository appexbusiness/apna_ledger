import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/widgets/powered_by.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../settings/presentation/security_providers.dart';

/// Branded splash on the navy vault: the logo flips in in 3D with an
/// orbiting coin, then a 3D feature carousel cycles while the app boots.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  int _feature = 0;
  late final _timer = Stream<int>.periodic(
    const Duration(milliseconds: 1000),
    (i) => i,
  ).listen((i) {
    if (mounted) setState(() => _feature = i);
  });

  static const _features = [
    (FinGlyph.income, 'One-tap entries', 'Log income & spending instantly'),
    (FinGlyph.analytics, 'Clear insights', 'See where your money goes'),
    (FinGlyph.given, 'Money given & taken', 'Track loans with people'),
    (
      FinGlyph.security,
      'Private & secure',
      'No bank details, only your hisaab'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer; // start the carousel
    Future.delayed(const Duration(milliseconds: 3200), _go);
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
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final scale = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: AppMotion.bouncy));
    final rotate = Tween(begin: 1.4, end: 0.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    final f = _features[_feature % _features.length];

    return Scaffold(
      body: HeroPanel(
        radius: 0,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: 200,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _c,
                        builder: (context, child) => Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateY(rotate.value)
                            ..scaleByDouble(
                              scale.value,
                              scale.value,
                              scale.value,
                              1,
                            ),
                          child: Opacity(opacity: fade.value, child: child),
                        ),
                        child: Floating(
                          amplitude: 5,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  blurRadius: 44,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/branding/logo_512.png',
                              height: 120,
                              width: 120,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 4,
                        child: FadeTransition(
                          opacity: fade,
                          child: const Floating(
                            phase: 0.4,
                            child: SpinningCoin(size: 48),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 16,
                        child: FadeTransition(
                          opacity: fade,
                          child: const Floating(
                            phase: 0.8,
                            amplitude: 4,
                            child: Coin3D(size: 30, turn: 0.08),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: [
                      Text(
                        l10n.appName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.tagline,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // Auto-cycling feature carousel
                SizedBox(
                  height: 130,
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
                          Icon3D(glyph: f.$1, size: 52, coin: false),
                          const SizedBox(height: 12),
                          Text(
                            f.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f.$3,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                              ? const Color(0xFFFFD56A)
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
                const Spacer(flex: 2),
                const PoweredByAppex(onDark: true),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
