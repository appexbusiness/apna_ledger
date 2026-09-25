import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/india_states.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/india_phone_prefix.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/pages/info_pages.dart';
import '../providers/auth_controller.dart';
import '../providers/google_auth.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/services/otp_service.dart';
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
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
        _snack(e.message == 'otpLimitReached'
            ? l10n.otpLimitReached
            : l10n.otpSendFailed);
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
              fullName: _name.text.trim().isEmpty
                  ? google.name
                  : _name.text.trim(),
              password: _password.text.isEmpty ? null : _password.text,
            );
        ref.read(googlePrefillProvider.notifier).state = null;
      } else {
        await ref.read(authControllerProvider.notifier).register(
              phone: phone,
              password: _password.text,
              fullName:
                  _name.text.trim().isEmpty ? null : _name.text.trim(),
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGoogle = ref.watch(googlePrefillProvider) != null;
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
                    BrandHeader(
                      title: l10n.register,
                      subtitle: l10n.registerSubtitle,
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _phone,
                      label: l10n.mobileNumber,
                      hint: '9876543210',
                      prefix: const IndiaPhonePrefix(),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),
                    if (!isGoogle) ...[
                      AppTextField(
                        controller: _password,
                        label: l10n.password,
                        obscure: _obscure,
                        validator: Validators.password,
                        suffix: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirm,
                        label: l10n.confirmPassword,
                        obscure: _obscure,
                        validator: (v) => v != _password.text
                            ? l10n.confirmPassword
                            : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _OptionalDivider(label: l10n.optional),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _name,
                      label: l10n.fullName,
                    ),
                    const SizedBox(height: 16),
                    _PickerField(
                      label: l10n.dob,
                      value: _dob == null ? null : Formatters.fullDate(_dob!),
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickDob,
                    ),
                    const SizedBox(height: 16),
                    _StateDropdown(
                      label: l10n.place,
                      value: _state,
                      onChanged: (v) => setState(() => _state = v),
                    ),
                    const SizedBox(height: 20),
                    _ConsentRow(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: l10n.sendOtp,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    const GoogleButton(),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text(l10n.alreadyHaveAccount),
                      ),
                    ),
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

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: onChanged),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l10n.agreeConsent),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Wrap(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const TermsPage()),
                ),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 0)),
                child: Text(l10n.termsConditions),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyPage()),
                ),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 0)),
                child: Text(l10n.privacyPolicy),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionalDivider extends StatelessWidget {
  const _OptionalDivider({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('( $label )',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(prefixIcon: Icon(icon)),
            child: Text(value ?? '—',
                style: text.bodyLarge?.copyWith(
                  color: value == null ? text.bodySmall?.color : null,
                )),
          ),
        ),
      ],
    );
  }
}

class _StateDropdown extends StatelessWidget {
  const _StateDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          hint: const Text('—'),
          items: IndiaStates.all
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
