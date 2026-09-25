import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/india_phone_prefix.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/google_button.dart';
import '../providers/auth_controller.dart';
import '../widgets/brand_header.dart';

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

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            phone: _phone.text.trim(),
            password: _password.text,
          );
      // Router redirect takes over on success.
    } on AppFailure catch (_) {
      _snack(l10n.loginFailed);
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
    return Scaffold(
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
                      title: l10n.welcomeBack,
                      subtitle: l10n.loginSubtitle,
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      controller: _phone,
                      label: l10n.mobileNumber,
                      hint: '9876543210',
                      prefix: const IndiaPhonePrefix(),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _password,
                      label: l10n.password,
                      hint: '••••••',
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot'),
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: l10n.login,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 14),
                    const GoogleButton(),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(l10n.dontHaveAccount),
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
