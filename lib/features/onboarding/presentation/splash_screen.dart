import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/powered_by.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../settings/presentation/security_providers.dart';

/// Branded, animated splash with a small auto-cycling feature carousel that
/// highlights key features while the app boots, then routes onward.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  int _feature = 0;
  late final _timer = Stream<int>.periodic(
      const Duration(milliseconds: 1000), (i) => i).listen((i) {
    if (mounted) setState(() => _feature = i);
  });

  static const _features = [
    (Icons.flash_on_rounded, 'One-tap entries', 'Log income & spending instantly'),
    (Icons.pie_chart_outline_rounded, 'Clear insights', 'See where your money goes'),
    (Icons.handshake_outlined, 'Money given & taken', 'Track loans with people'),
    (Icons.lock_outline_rounded, 'Private & secure', 'No bank details, only your hisaab'),
  ];

  @override
  void initState() {
    super.initState();
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
    final scale = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    final rotate = Tween(begin: 1.2, end: 0.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    final f = _features[_feature % _features.length];

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(rotate.value)
                  ..scale(scale.value),
                child: Opacity(opacity: fade.value, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.18),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Image.asset('assets/branding/logo_512.png',
                    height: 128, width: 128),
              ),
            ),
            const SizedBox(height: 18),
            FadeTransition(
              opacity: fade,
              child: Text(l10n.appName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
            ),
            const Spacer(flex: 2),
            // Auto-cycling feature carousel
            SizedBox(
              height: 96,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                            begin: const Offset(0, 0.25), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_feature),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.$1, color: Colors.white, size: 30),
                    const SizedBox(height: 10),
                    Text(f.$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(f.$3,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _features.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: (i == _feature % _features.length) ? 18 : 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                          alpha: (i == _feature % _features.length) ? 1 : 0.4),
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
    );
  }
}
