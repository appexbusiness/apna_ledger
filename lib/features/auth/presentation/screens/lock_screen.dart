import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/security_providers.dart';

/// Launch lock: accepts the 4-digit PIN (if set) and/or biometric unlock.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pin = TextEditingController();
  bool _busy = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // If biometric app-lock is on, prompt it immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appLockProvider)) _biometric();
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
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

  void _onPinChanged(String value) {
    if (value.length == 4) {
      if (ref.read(pinProvider.notifier).verify(value)) {
        context.go('/dashboard');
      } else {
        setState(() {
          _error = true;
          _pin.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPin = ref.watch(pinProvider);
    final biometricOn = ref.watch(appLockProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/branding/logo_512.png',
                    height: 92, width: 92),
                const SizedBox(height: 20),
                const Icon(Icons.lock_outline_rounded,
                    color: Colors.white, size: 30),
                const SizedBox(height: 10),
                Text(l10n.appLocked,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 28),
                if (hasPin) ...[
                  Text(l10n.enterPin,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _pin,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      obscuringCharacter: '●',
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 18),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.12),
                        errorText: _error ? l10n.wrongPin : null,
                        errorStyle: const TextStyle(color: Color(0xFFFFC9C9)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Colors.white, width: 1.6),
                        ),
                      ),
                      onChanged: _onPinChanged,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (biometricOn)
                  TextButton.icon(
                    onPressed: _busy ? null : _biometric,
                    icon: const Icon(Icons.fingerprint_rounded,
                        color: Colors.white),
                    label: Text(l10n.unlock,
                        style: const TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
