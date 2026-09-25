import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_controller.dart';
import '../providers/google_auth.dart';

/// "Continue with Google" — for both new and returning users.
/// • Existing linked email  → logs straight in (no OTP).
/// • New email              → phone + OTP once, then links Google.
/// Any real Google error is shown verbatim so it can be reported.
class GoogleButton extends ConsumerStatefulWidget {
  const GoogleButton({super.key});

  @override
  ConsumerState<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends ConsumerState<GoogleButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final result = await ref.read(googleSignInServiceProvider).pick();
    if (!mounted) return;

    if (result.cancelled) {
      setState(() => _busy = false);
      return; // user closed the popup — no error
    }
    if (result.error != null) {
      setState(() => _busy = false);
      _showError(result.error!);
      return;
    }

    final email = result.account?.email ?? '';
    try {
      if (email.isNotEmpty) {
        final matches = await ref
            .read(authControllerProvider.notifier)
            .usersByEmail(email);
        if (!mounted) return;
        if (matches.length == 1) {
          // Returning user with a verified/linked mobile → straight in.
          await ref.read(authControllerProvider.notifier).loginByEmail(email);
          if (mounted) context.go('/dashboard');
          return;
        }
      }
      // New (or ambiguous) → mobile verification (phone + OTP) is required once.
      if (mounted) {
        setState(() => _busy = false);
        ref.read(googlePrefillProvider.notifier).state = result.account;
        context.go('/register');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    final l10n = AppLocalizations.of(context);
    showAppSheet<void>(
      context,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnimatedStatusIcon(type: ToastType.error, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.googleSignInFailed,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaces.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              message,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: l10n.retry,
            icon: Icons.refresh_rounded,
            onPressed: () {
              Navigator.pop(context);
              _run();
            },
          ),
          const SizedBox(height: 8),
          AppButton(
            label: l10n.cont,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = context.surfaces;
    return Pressable(
      onTap: _busy ? null : _run,
      semanticLabel: l10n.continueWithGoogle,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.cardHi, s.card],
          ),
          border: Border.all(color: context.semantic.border),
          boxShadow: s.elevation(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: _busy
                  ? const SizedBox(
                      key: ValueKey('busy'),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : SvgPicture.asset(
                      'assets/branding/google_g.svg',
                      key: const ValueKey('g'),
                      height: 22,
                      width: 22,
                    ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.continueWithGoogle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
