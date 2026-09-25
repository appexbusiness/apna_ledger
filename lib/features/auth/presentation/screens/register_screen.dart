import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/otp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/date_sheet.dart';
import '../../../../core/widgets/india_phone_prefix.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/pages/edit_profile_page.dart';
import '../../../settings/presentation/pages/info_pages.dart';
import '../providers/auth_controller.dart';
import '../providers/google_auth.dart';
import '../widgets/brand_header.dart';
import '../widgets/google_button.dart';
import '../widgets/otp_sheet.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();

  DateTime? _dob;
  String? _state;
  bool _loading = false;
  bool _obscure = true;
  bool _agree = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill name/email if the user arrived via "Continue with Google".
    final prefill = ref.read(googlePrefillProvider);
    if (prefill != null) {
      if ((prefill.name ?? '').isNotEmpty) _name.text = prefill.name!;
    }
  }

  @override
  void dispose() {
    for (final c in [_phone, _password, _confirm, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initial: _dob ?? DateTime(now.year - 20),
      first: DateTime(1920),
      last: now,
      title: AppLocalizations.of(context).dob,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickState() async {
    final picked = await showStatePickerSheet(
      context,
      selected: _state,
      title: AppLocalizations.of(context).place,
    );
    if (picked != null) setState(() => _state = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      setState(() => _shake++);
      return;
    }
    if (!_agree) {
      setState(() => _shake++);
      _snack(l10n.mustAgree);
      return;
    }
    final phone = _phone.text.trim();
    final google = ref.read(googlePrefillProvider);

    // For normal sign-up, block an already-registered number. For a Google
    // sign-up we allow it — the phone may already exist and we map the email
    // onto it (link accounts).
    if (google == null &&
        await ref.read(authRepositoryProvider).phoneExists(phone)) {
      if (mounted) _snack(l10n.accountExists);
      return;
    }

    // OTP is compulsory, capped at 3 sends/day for this number.
    OtpSendResult sendResult;
    try {
      sendResult = await ref.read(otpServiceProvider).sendOtp(phone);
    } on AppFailure catch (e) {
      if (mounted) {
        _snack(
          e.message == 'otpLimitReached'
              ? l10n.otpLimitReached
              : l10n.otpSendFailed,
        );
      }
      return;
    }
    if (!mounted) return;
    final verified =
        await showOtpSheet(context, ref, phone, initialResult: sendResult);
    if (!verified) return;

    setState(() => _loading = true);
    try {
      if (google != null) {
        // Google sign-up: reconcile email ↔ verified phone.
        await ref.read(authControllerProvider.notifier).resolveGoogleSignup(
              email: google.email ?? '',
              phone: phone,
              fullName:
                  _name.text.trim().isEmpty ? google.name : _name.text.trim(),
              password: _password.text.isEmpty ? null : _password.text,
            );
        ref.read(googlePrefillProvider.notifier).state = null;
      } else {
        await ref.read(authControllerProvider.notifier).register(
              phone: phone,
              password: _password.text,
              fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
              dob: _dob,
              state: _state,
            );
      }
    } on AppFailure catch (_) {
      _snack(l10n.accountExists);
    } catch (_) {
      _snack(l10n.somethingWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (mounted) Toaster.of(context).error(msg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGoogle = ref.watch(googlePrefillProvider) != null;
    return AuthScaffold(
      title: l10n.register,
      subtitle: l10n.registerSubtitle,
      onBack: () => context.pop(),
      footer: Center(
        child: TextButton(
          onPressed: () => context.pop(),
          child: Text(l10n.alreadyHaveAccount),
        ),
      ),
      children: [
        Form(
          key: _formKey,
          child: Shake(
            trigger: _shake,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _phone,
                  label: l10n.mobileNumber,
                  hint: '9876543210',
                  prefix: const IndiaPhonePrefix(),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                if (!isGoogle) ...[
                  AppTextField(
                    controller: _password,
                    label: l10n.password,
                    icon: Icons.lock_rounded,
                    obscure: _obscure,
                    validator: Validators.password,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _confirm,
                    label: l10n.confirmPassword,
                    icon: Icons.lock_reset_rounded,
                    obscure: _obscure,
                    validator: (v) =>
                        v != _password.text ? l10n.confirmPassword : null,
                  ),
                  const SizedBox(height: 20),
                ],
                OrDivider(label: '( ${l10n.optional} )'),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _name,
                  label: l10n.fullName,
                  icon: Icons.person_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                AppPickerField(
                  label: l10n.dob,
                  value: _dob == null ? null : Formatters.fullDate(_dob!),
                  icon: Icons.cake_rounded,
                  leading: const Icon3D(
                    glyph: FinGlyph.calendar,
                    size: 36,
                    style: Icon3DStyle.soft,
                  ),
                  onTap: _pickDob,
                ),
                const SizedBox(height: 14),
                AppPickerField(
                  label: l10n.place,
                  value: _state,
                  leading: const Icon3D(
                    icon: Icons.location_on_rounded,
                    color: AppColors.info,
                    size: 36,
                    style: Icon3DStyle.soft,
                  ),
                  onTap: _pickState,
                ),
                const SizedBox(height: 18),
                _ConsentRow(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: l10n.sendOtp,
          icon: Icons.sms_rounded,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 16),
        const OrDivider(),
        const SizedBox(height: 16),
        const GoogleButton(),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          onTap: () {
            AppHaptics.select();
            onChanged(!value);
          },
          haptic: false,
          pressedScale: 0.98,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.emphasized,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? c : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value ? c : context.semantic.muted,
                    width: 2,
                  ),
                  boxShadow: value ? AppSurfaces.glow(c, strength: 0.5) : null,
                ),
                child: value
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white,)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    l10n.agreeConsent,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Wrap(
            children: [
              TextButton(
                onPressed: () => showInfoSheet(
                  context,
                  title: l10n.termsConditions,
                  glyph: FinGlyph.legal,
                  children: termsChildren(),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(l10n.termsConditions),
              ),
              TextButton(
                onPressed: () => showInfoSheet(
                  context,
                  title: l10n.privacyPolicy,
                  glyph: FinGlyph.privacy,
                  children: privacyPolicyChildren(),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(l10n.privacyPolicy),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
