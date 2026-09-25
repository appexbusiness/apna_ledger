import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/india_phone_prefix.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_controller.dart';
import '../widgets/brand_header.dart';
import '../widgets/google_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  int _shake = 0;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    if (!_formKey.currentState!.validate()) {
      setState(() => _shake++);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            phone: _phone.text.trim(),
            password: _password.text,
          );
      // Router redirect takes over on success.
    } on AppFailure catch (_) {
      setState(() => _shake++);
      toast.error(l10n.loginFailed);
    } catch (_) {
      toast.error(l10n.somethingWrong, retryLabel: l10n.retry, onRetry: _submit);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: l10n.welcomeBack,
      subtitle: l10n.loginSubtitle,
      footer: Center(
        child: TextButton(
          onPressed: () => context.push('/register'),
          child: Text(l10n.dontHaveAccount),
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _password,
                  label: l10n.password,
                  hint: '••••••',
                  icon: Icons.lock_rounded,
                  obscure: _obscure,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    icon: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        key: ValueKey(_obscure),
                      ),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot'),
            child: Text(l10n.forgotPassword),
          ),
        ),
        const SizedBox(height: 4),
        AppButton(
          label: l10n.login,
          icon: Icons.arrow_forward_rounded,
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
