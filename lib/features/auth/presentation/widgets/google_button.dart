import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
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
    final l10n = AppLocalizations.of(context);
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: context.semantic.expense),
        title: Text(l10n.googleSignInFailed),
        content: SingleChildScrollView(
          child: SelectableText(message,
              style: const TextStyle(fontSize: 12.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cont),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : SvgPicture.asset('assets/branding/google_g.svg',
              height: 20, width: 20),
      label: Text(l10n.continueWithGoogle),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: context.semantic.border),
      ),
    );
  }
}
