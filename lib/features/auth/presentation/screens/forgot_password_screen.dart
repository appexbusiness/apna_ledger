import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/otp_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
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

  void _snack(String msg, {bool error = true}) {
    final toast = Toaster.of(context);
    error ? toast.error(msg) : toast.success(msg);
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
      _snack(
        e.message == 'otpLimitReached'
            ? l10n.otpLimitReached
            : l10n.otpSendFailed,
      );
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
      showSuccessBurst(context, message: l10n.passwordUpdatedLogin);
      context.go('/login');
    } catch (_) {
      _snack(l10n.somethingWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _progress => switch (_step) {
        _Step.phone => 0,
        _Step.rememberChoice || _Step.oldPassword => 1,
        _Step.newPassword => 2,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: l10n.resetPassword,
      subtitle: l10n.mobileNumber,
      onBack: () => context.pop(),
      children: [
        _StepTrack(current: _progress),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _phone,
                label: l10n.mobileNumber,
                prefix: const IndiaPhonePrefix(),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: _step == _Step.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.spring,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _stepBody(l10n),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepBody(AppLocalizations l10n) {
    switch (_step) {
      case _Step.phone:
        return AppButton(
          label: l10n.cont,
          icon: Icons.arrow_forward_rounded,
          loading: _loading,
          onPressed: _continueFromPhone,
        );
      case _Step.rememberChoice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.rememberPasswordQuestion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            SheetOption(
              title: l10n.yesRememberIt,
              glyph: FinGlyph.key,
              onTap: _chooseRemembered,
            ),
            SheetOption(
              title: l10n.noSendOtp,
              glyph: FinGlyph.phone,
              trailing: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _loading ? () {} : _chooseForgot,
            ),
          ],
        );
      case _Step.oldPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _oldPassword,
              label: l10n.currentPassword,
              icon: Icons.lock_rounded,
              obscure: true,
              errorText: _oldPasswordError,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: l10n.cont,
              icon: Icons.arrow_forward_rounded,
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
        );
      case _Step.newPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_viaOtp)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 18, color: context.semantic.income,),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.passwordVerifiedNoOtp,
                        style: TextStyle(
                          color: context.semantic.income,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            AppTextField(
              controller: _newPassword,
              label: l10n.newPassword,
              icon: Icons.lock_reset_rounded,
              obscure: true,
              validator: Validators.password,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _confirmPassword,
              label: l10n.confirmPassword,
              icon: Icons.lock_reset_rounded,
              obscure: true,
              validator: (v) =>
                  v != _newPassword.text ? l10n.confirmPassword : null,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: l10n.resetPassword,
              icon: Icons.check_rounded,
              loading: _loading,
              onPressed: _reset,
            ),
          ],
        );
    }
  }
}

/// Three-step progress track (phone → verify → new password).
class _StepTrack extends StatelessWidget {
  const _StepTrack({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    const icons = [
      Icons.phone_iphone_rounded,
      Icons.verified_user_rounded,
      Icons.lock_reset_rounded,
    ];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= current ? c : context.surfaces.surface2,
              boxShadow: i == current ? AppSurfaces.glow(c, strength: 0.6) : null,
            ),
            child: Icon(
              i < current ? Icons.check_rounded : icons[i],
              size: 18,
              color: i <= current ? Colors.white : context.semantic.muted,
            ),
          ),
          if (i < 2)
            Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: context.surfaces.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: AppMotion.slow,
                  curve: AppMotion.enter,
                  widthFactor: i < current ? 1 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
