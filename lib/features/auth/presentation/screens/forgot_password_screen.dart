import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/otp_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/india_phone_prefix.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_controller.dart';
import '../widgets/brand_header.dart';
import '../widgets/otp_sheet.dart';

enum _Step { phone, rememberChoice, oldPassword, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _State();
}

class _State extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  _Step _step = _Step.phone;
  bool _loading = false;
  String? _oldPasswordError;
  bool _viaOtp = false;

  @override
  void dispose() {
    _phone.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _continueFromPhone() async {
    final l10n = AppLocalizations.of(context);
    if (Validators.phone(_phone.text) != null) {
      _formKey.currentState!.validate();
      return;
    }
    setState(() => _loading = true);
    final phone = _phone.text.trim();
    final exists = await ref.read(authRepositoryProvider).phoneExists(phone);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!exists) {
      _snack(l10n.loginFailed);
      return;
    }
    setState(() => _step = _Step.rememberChoice);
  }

  void _chooseRemembered() => setState(() => _step = _Step.oldPassword);

  Future<void> _chooseForgot() => _sendOtpAndVerify();

  Future<void> _confirmOldPassword() async {
    final l10n = AppLocalizations.of(context);
    if (_oldPassword.text.isEmpty) return;
    setState(() {
      _loading = true;
      _oldPasswordError = null;
    });
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyPassword(_phone.text.trim(), _oldPassword.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      // Remembered the password correctly → straight to reset, no OTP.
      setState(() {
        _viaOtp = false;
        _step = _Step.newPassword;
      });
    } else {
      setState(() => _oldPasswordError = l10n.oldPasswordIncorrect);
    }
  }

  Future<void> _sendOtpAndVerify() async {
    final l10n = AppLocalizations.of(context);
    final phone = _phone.text.trim();
    setState(() => _loading = true);
    OtpSendResult sendResult;
    try {
      sendResult = await ref.read(otpServiceProvider).sendOtp(phone);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.message == 'otpLimitReached'
          ? l10n.otpLimitReached
          : l10n.otpSendFailed);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    final verified =
        await showOtpSheet(context, ref, phone, initialResult: sendResult);
    if (!verified || !mounted) return;
    setState(() {
      _viaOtp = true;
      _step = _Step.newPassword;
    });
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            phone: _phone.text.trim(),
            newPassword: _newPassword.text,
          );
      if (!mounted) return;
      _snack(l10n.passwordUpdatedLogin);
      context.go('/login');
    } catch (_) {
      _snack(l10n.somethingWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrandHeader(title: l10n.resetPassword),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _phone,
                      label: l10n.mobileNumber,
                      prefix: const IndiaPhonePrefix(),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      enabled: _step == _Step.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 20),
                    if (_step == _Step.phone)
                      AppButton(
                        label: l10n.cont,
                        loading: _loading,
                        onPressed: _continueFromPhone,
                      ),
                    if (_step == _Step.rememberChoice) ...[
                      Text(l10n.rememberPasswordQuestion,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      AppButton(
                        label: l10n.yesRememberIt,
                        onPressed: _chooseRemembered,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _loading ? null : _chooseForgot,
                        child: Text(l10n.noSendOtp),
                      ),
                    ],
                    if (_step == _Step.oldPassword) ...[
                      AppTextField(
                        controller: _oldPassword,
                        label: l10n.currentPassword,
                        obscure: true,
                        errorText: _oldPasswordError,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: l10n.cont,
                        loading: _loading,
                        onPressed: _confirmOldPassword,
                      ),
                      if (_oldPasswordError != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _loading ? null : _sendOtpAndVerify,
                            child: Text(l10n.forgotItSendOtp),
                          ),
                        ),
                      ],
                    ],
                    if (_step == _Step.newPassword) ...[
                      if (!_viaOtp)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(l10n.passwordVerifiedNoOtp,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      AppTextField(
                        controller: _newPassword,
                        label: l10n.newPassword,
                        obscure: true,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPassword,
                        label: l10n.confirmPassword,
                        obscure: true,
                        validator: (v) => v != _newPassword.text
                            ? l10n.confirmPassword
                            : null,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: l10n.resetPassword,
                        loading: _loading,
                        onPressed: _reset,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
