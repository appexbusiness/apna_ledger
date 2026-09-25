import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/security_providers.dart';

/// Launch lock: accepts the 4-digit PIN (if set) on a custom keypad and/or
/// biometric unlock.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _busy = false;
  bool _error = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    // If biometric app-lock is on, prompt it immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appLockProvider)) _biometric();
    });
  }

  Future<void> _biometric() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(biometricServiceProvider)
        .authenticate(l10n.unlockReason);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) context.go('/dashboard');
  }

  void _press(String k) {
    AppHaptics.select();
    setState(() {
      _error = false;
      if (k == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        return;
      }
      if (_pin.length < 4) _pin += k;
    });
    if (_pin.length == 4) _check();
  }

  void _check() {
    if (ref.read(pinProvider.notifier).verify(_pin)) {
      AppHaptics.medium();
      context.go('/dashboard');
    } else {
      setState(() {
        _error = true;
        _shake++;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPin = ref.watch(pinProvider);
    final biometricOn = ref.watch(appLockProvider);

    return Scaffold(
      body: HeroPanel(
        radius: 0,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const Spacer(),
                  const Entrance(
                    scaleFrom: 0.6,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        BrandLogo(size: 120, haloColor: AppColors.accent),
                        Positioned(
                          right: 10,
                          bottom: 14,
                          child: Icon3D(glyph: FinGlyph.lock, size: 40),
                        ),
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Floating(
                            phase: 0.5,
                            amplitude: 4,
                            child: SpinningCoin(size: 38),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Entrance(
                    index: 1,
                    child: Text(
                      l10n.appLocked,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Text(
                      _error
                          ? l10n.wrongPin
                          : (hasPin ? l10n.enterPin : l10n.unlockReason),
                      key: ValueKey(_error),
                      style: TextStyle(
                        color: _error
                            ? const Color(0xFFFFB4B4)
                            : Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (hasPin)
                    Shake(
                      trigger: _shake,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 4; i++)
                            AnimatedContainer(
                              duration: AppMotion.medium,
                              curve: AppMotion.emphasized,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: i < _pin.length ? 18 : 14,
                              height: i < _pin.length ? 18 : 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _error
                                    ? AppColors.expense
                                    : (i < _pin.length
                                        ? AppColors.accent
                                        : Colors.white.withValues(alpha: 0.18)),
                                boxShadow: i < _pin.length
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.6),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  if (hasPin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: _Keypad(
                        onKey: _press,
                        biometric: biometricOn ? _biometric : null,
                        busy: _busy,
                      ),
                    )
                  else if (biometricOn)
                    Pressable(
                      onTap: _busy ? null : _biometric,
                      child: Column(
                        children: [
                          const Icon3D(glyph: FinGlyph.fingerprint, size: 72),
                          const SizedBox(height: 10),
                          Text(
                            l10n.unlock,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey, this.biometric, this.busy = false});
  final ValueChanged<String> onKey;
  final VoidCallback? biometric;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['bio', '0', '⌫'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final k in row)
                  if (k == 'bio')
                    _GlassKey(
                      onTap: biometric == null || busy ? null : biometric,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 30,
                        color: biometric == null
                            ? Colors.transparent
                            : Colors.white,
                      ),
                    )
                  else if (k == '⌫')
                    _GlassKey(
                      onTap: () => onKey(k),
                      child: const Icon(
                        Icons.backspace_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  else
                    _GlassKey(
                      onTap: () => onKey(k),
                      child: Text(
                        k,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
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

class _GlassKey extends StatelessWidget {
  const _GlassKey({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.86,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: onTap == null
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          border: onTap == null
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
