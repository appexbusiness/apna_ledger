import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/otp_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pin_input.dart';

/// Reusable OTP verification sheet. Assumes an OTP has ALREADY been sent to
/// [phone] (via [OtpService.sendOtp]) right before this is shown — pass the
/// [initialResult] from that call so the sheet can show the right resend
/// countdown and remaining-today count from the start.
/// Returns `true` once the correct code is entered.
Future<bool> showOtpSheet(
  BuildContext context,
  WidgetRef ref,
  String phone, {
  OtpSendResult? initialResult,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showAppSheet<bool>(
    context,
    title: l10n.verifyOtp,
    subtitle: l10n.otpHint(phone),
    glyph: FinGlyph.security,
    builder: (_, __) =>
        _OtpSheet(phone: phone, ref: ref, initialResult: initialResult),
  );
  return result ?? false;
}

class _OtpSheet extends StatefulWidget {
  const _OtpSheet({required this.phone, required this.ref, this.initialResult});
  final String phone;
  final WidgetRef ref;
  final OtpSendResult? initialResult;

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  final _controller = TextEditingController();
  String? _error;
  int _shake = 0;
  bool _loading = false;
  bool _resending = false;
  int _cooldown = 0;
  int _remainingToday = OtpService.maxPerDay;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final r = widget.initialResult;
    if (r != null) {
      _cooldown = r.cooldownSeconds;
      _remainingToday = r.remainingToday;
    } else {
      _remainingToday =
          widget.ref.read(otpServiceProvider).remainingToday(widget.phone);
    }
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    if (_cooldown <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      if (_cooldown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final r = await widget.ref.read(otpServiceProvider).sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _cooldown = r.cooldownSeconds;
        _remainingToday = r.remainingToday;
        _resending = false;
      });
      _startTicker();
      Toaster.of(context).info(l10n.otpResent);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _error = _messageFor(e, l10n);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _error = l10n.otpSendFailed;
      });
    }
  }

  String _messageFor(AppFailure e, AppLocalizations l10n) {
    switch (e.message) {
      case 'otpLimitReached':
        return l10n.otpLimitReached;
      case 'otpResendTooSoon':
        return l10n.otpResendTooSoon;
      default:
        return l10n.otpSendFailed;
    }
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    if (_controller.text.trim().length < 4) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final ok = widget.ref
        .read(otpServiceProvider)
        .verifyOtp(widget.phone, _controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = l10n.invalidOtp;
        _shake++;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = context.semantic.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Text(
          l10n.enterOtp,
          style: TextStyle(color: muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        PinBoxes(
          controller: _controller,
          length: 6,
          obscure: false,
          autofocus: true,
          errorTrigger: _shake,
          hasError: _error != null,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: (_) => _verify(),
        ),
        AnimatedSize(
          duration: AppMotion.fast,
          child: _error == null
              ? const SizedBox(height: 18)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.semantic.expense,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        AppButton(
          label: l10n.verifyOtp,
          icon: Icons.verified_user_rounded,
          loading: _loading,
          onPressed: _verify,
        ),
        const SizedBox(height: 12),
        _resending
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_cooldown > 0) ...[
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: _cooldown / OtpService.resendCooldown.inSeconds,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: (_cooldown > 0 || _remainingToday <= 0)
                        ? null
                        : _resend,
                    child: Text(
                      _cooldown > 0
                          ? l10n.otpResendIn(_cooldown)
                          : (_remainingToday <= 0
                              ? l10n.otpLimitReached
                              : l10n.resendOtp),
                    ),
                  ),
                ],
              ),
        if (_remainingToday > 0)
          Text(
            l10n.otpAttemptsLeft(_remainingToday),
            style: TextStyle(color: muted, fontSize: 12),
          ),
      ],
    );
  }
}
