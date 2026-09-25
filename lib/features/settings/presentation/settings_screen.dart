import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/env_config.dart';
import '../../../core/config/flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_links.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/powered_by.dart';
import 'pages/edit_profile_page.dart';
import 'pages/info_pages.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../auth/presentation/providers/google_auth.dart';
import '../../../core/error/failure.dart';
import '../../../core/services/biometric_service.dart';
import 'app_settings_controller.dart';
import 'security_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _languages = <String, String>{
    'en': 'English',
    'hi': 'हिन्दी',
    'gu': 'ગુજરાતી',
    'bn': 'বাংলা',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                if (!EnvConfig.instance.flavor.isProduction) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.semantic.loanGiven
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science_outlined,
                              size: 16, color: context.semantic.loanGiven),
                          const SizedBox(width: 6),
                          Text(
                            'Environment: ${EnvConfig.instance.flavor.label}',
                            style: TextStyle(
                                color: context.semantic.loanGiven,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // ---- Account / profile ----
                _SectionLabel(l10n.account),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.14),
                          child: Text(
                            (user?.displayName.isNotEmpty ?? false)
                                ? user!.displayName
                                    .substring(0, 1)
                                    .toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(user?.displayName ?? ''),
                        subtitle: Text('+91 ${user?.phone ?? ''}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showEditProfileSheet(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(l10n.editProfile),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showEditProfileSheet(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---- Language ----
                _SectionLabel(l10n.language),
                Card(
                  child: Column(
                    children: [
                      for (final entry in _languages.entries)
                        RadioListTile<String>(
                          value: entry.key,
                          groupValue: settings.locale.languageCode,
                          onChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setLocale(Locale(v!)),
                          title: Text(entry.value),
                          dense: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---- Theme ----
                _SectionLabel(l10n.theme),
                Card(
                  child: Column(
                    children: [
                      _ThemeTile(
                        label: l10n.lightTheme,
                        icon: Icons.light_mode_outlined,
                        mode: ThemeMode.light,
                        current: settings.themeMode,
                      ),
                      _ThemeTile(
                        label: l10n.darkTheme,
                        icon: Icons.dark_mode_outlined,
                        mode: ThemeMode.dark,
                        current: settings.themeMode,
                      ),
                      _ThemeTile(
                        label: l10n.systemTheme,
                        icon: Icons.brightness_auto_outlined,
                        mode: ThemeMode.system,
                        current: settings.themeMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---- Security ----
                _SectionLabel(l10n.security),
                Card(
                  child: Column(
                    children: const [
                      _AppLockTile(),
                      Divider(height: 1),
                      _PinTile(),
                      Divider(height: 1),
                      _ChangePasswordTile(),
                      Divider(height: 1),
                      _GoogleAccountTile(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---- Help & legal ----
                _SectionLabel('Help & legal'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.support_agent_outlined),
                        title: Text(l10n.help),
                        subtitle: Text(l10n.helpEmail,
                            style: TextStyle(
                                color: context.semantic.muted, fontSize: 12)),
                        onTap: () => openUrl(
                            'mailto:${l10n.helpEmail}?subject=Apna%20Ledger%20Support'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: Text(l10n.howToUse),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            context.push('/dashboard/settings/how-to'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.ios_share_rounded),
                        title: Text(l10n.shareApp),
                        onTap: () => Share.share(
                          'I track every paisa with ${l10n.appName} — simple, private hisaab in your language. Try it!',
                          subject: l10n.appName,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: Text(l10n.privacyPolicy),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showInfoSheet(context,
                            title: l10n.privacyPolicy,
                            children: privacyPolicyChildren()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(l10n.termsConditions),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showInfoSheet(context,
                            title: l10n.termsConditions,
                            children: termsChildren()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(l10n.aboutApp),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showInfoSheet(context,
                            title: l10n.aboutApp,
                            children: aboutChildren(context, l10n)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ---- Logout ----
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: Icon(Icons.logout_rounded,
                      color: context.semantic.expense),
                  label: Text(
                    l10n.logout,
                    style: TextStyle(color: context.semantic.expense),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color:
                            context.semantic.expense.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: PoweredByAppex()),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '${l10n.appName} · v1.0.0',
                    style: TextStyle(
                        color: context.semantic.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text('${l10n.logout}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

}

class _PinTile extends ConsumerWidget {
  const _PinTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasPin = ref.watch(pinProvider);
    return ListTile(
      leading: Icon(Icons.pin_outlined,
          color: hasPin ? Theme.of(context).colorScheme.primary : null),
      title: Text(l10n.setPin),
      subtitle: Text(l10n.pinSubtitle,
          style: TextStyle(color: context.semantic.muted, fontSize: 12)),
      trailing: hasPin
          ? TextButton(
              onPressed: () => ref.read(pinProvider.notifier).clear(),
              child: Text(l10n.removePin,
                  style: TextStyle(color: context.semantic.expense)),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: () => _setPin(context, ref),
    );
  }

  Future<void> _setPin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final pin1 = TextEditingController();
    final pin2 = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showAppSheet<bool>(
      context,
      title: l10n.setPin,
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pinField(pin1, l10n.enterPin),
          const SizedBox(height: 12),
          _pinField(pin2, l10n.confirmPin),
          const SizedBox(height: 20),
          AppButton(
              label: l10n.save, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (ok != true) return;
    final a = pin1.text.trim();
    final b = pin2.text.trim();
    if (a.length != 4 || b.length != 4) return;
    if (a != b) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pinMismatch)));
      return;
    }
    await ref.read(pinProvider.notifier).setPin(a);
    messenger.showSnackBar(SnackBar(content: Text(l10n.pinSet)));
  }

  Widget _pinField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, letterSpacing: 10),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
            labelText: label, counterText: '', border: const OutlineInputBorder()),
      );
}

class _AppLockTile extends ConsumerWidget {
  const _AppLockTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(appLockProvider);
    final available =
        ref.watch(biometricAvailableProvider).valueOrNull ?? false;
    final hasPin = ref.watch(pinProvider);

    return SwitchListTile(
      secondary: Icon(Icons.fingerprint_rounded,
          color: enabled ? Theme.of(context).colorScheme.primary : null),
      title: Text(l10n.appLock),
      subtitle: Text(l10n.appLockSubtitle,
          style: TextStyle(color: context.semantic.muted, fontSize: 12)),
      value: enabled,
      onChanged: (v) async {
        if (!v) {
          await ref.read(appLockProvider.notifier).set(false);
          return;
        }
        // Turning ON. Prefer confirming with biometric; otherwise a PIN must
        // exist so the user can always get back in.
        if (available) {
          final result = await ref
              .read(biometricServiceProvider)
              .authenticate(l10n.unlockReason);
          if (result.ok) {
            await ref.read(appLockProvider.notifier).set(true);
            return;
          }
          if (!context.mounted) return;
          final msg = switch (result.status) {
            BiometricStatus.notEnrolled => l10n.biometricNotEnrolled,
            BiometricStatus.lockedOut => l10n.biometricLockedOut,
            BiometricStatus.permissionDenied =>
              l10n.biometricPermissionDenied,
            BiometricStatus.cancelled => null, // user backed out; no error
            _ => l10n.biometricUnavailable,
          };
          if (msg != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        } else if (hasPin) {
          await ref.read(appLockProvider.notifier).set(true);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.biometricUnavailable)));
          }
        }
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.semantic.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.mode,
    required this.current,
  });
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = mode == current;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon,
          color: selected ? scheme.primary : context.semantic.muted),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : const SizedBox.shrink(),
      onTap: () => ref.read(appSettingsProvider.notifier).setThemeMode(mode),
    );
  }
}

/// Settings → Security → Change Password. Requires the current password.
class _ChangePasswordTile extends ConsumerWidget {
  const _ChangePasswordTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.lock_reset_outlined),
      title: Text(l10n.changePassword),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _run(context, ref),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final oldPwd = TextEditingController();
    final newPwd = TextEditingController();
    final confirmPwd = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    String? error;
    final ok = await showAppSheet<bool>(
      context,
      title: l10n.changePassword,
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: oldPwd,
            label: l10n.currentPassword,
            obscure: true,
            errorText: error,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: newPwd,
            label: l10n.newPassword,
            obscure: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: confirmPwd,
            label: l10n.confirmPassword,
            obscure: true,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: l10n.save,
            onPressed: () {
              if (newPwd.text.isEmpty || newPwd.text != confirmPwd.text) {
                setSheet(() => error = l10n.confirmPassword);
                return;
              }
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            oldPassword: oldPwd.text,
            newPassword: newPwd.text,
          );
      messenger.showSnackBar(SnackBar(content: Text(l10n.passwordUpdated)));
    } on AppFailure {
      messenger.showSnackBar(SnackBar(content: Text(l10n.wrongPassword)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.somethingWrong)));
    }
  }
}

/// Settings → Security → Google Account. Link / Change / Remove — none of
/// these send a mobile OTP (Google's own auth is the verification).
class _GoogleAccountTile extends ConsumerStatefulWidget {
  const _GoogleAccountTile();

  @override
  ConsumerState<_GoogleAccountTile> createState() =>
      _GoogleAccountTileState();
}

class _GoogleAccountTileState extends ConsumerState<_GoogleAccountTile> {
  bool _busy = false;

  Future<void> _linkOrChange({required bool isChange}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final service = ref.read(googleSignInServiceProvider);
    final result = isChange ? await service.pickDifferent() : await service.pick();
    if (!mounted) return;
    if (result.cancelled) {
      setState(() => _busy = false);
      return;
    }
    if (result.error != null) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    final notifier = ref.read(authControllerProvider.notifier);
    final err = isChange
        ? await notifier.changeGoogleEmail(
            result.account?.email ?? '', result.account?.name)
        : await notifier.linkGoogleEmail(
            result.account?.email ?? '', result.account?.name);
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = switch (err) {
      null => (isChange ? l10n.googleAccountChanged : l10n.emailVerifiedDone),
      'emailLinkedElsewhere' => l10n.emailLinkedElsewhere,
      'emailMismatchProfile' => l10n.googleEmailMismatch,
      _ => l10n.somethingWrong,
    };
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showAppConfirm(
      context,
      icon: Icons.link_off_rounded,
      title: l10n.removeGoogleAccount,
      message: l10n.removeGoogleConfirm,
      confirmLabel: l10n.removeGoogleAccount,
      danger: true,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    final err =
        await ref.read(authControllerProvider.notifier).removeGoogleLink();
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = switch (err) {
      null => l10n.googleAccountRemoved,
      'setPasswordFirst' => l10n.setPasswordFirstToRemoveGoogle,
      _ => l10n.somethingWrong,
    };
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider);
    final linked = (user?.email ?? '').isNotEmpty && (user?.emailVerified ?? false);

    return ListTile(
      leading: SvgPicture.asset('assets/branding/google_g.svg',
          height: 20, width: 20),
      title: Text(l10n.googleAccount),
      subtitle: Text(
        linked ? user!.email! : l10n.googleAccountNotLinked,
        style: TextStyle(color: context.semantic.muted, fontSize: 12),
      ),
      trailing: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'link') _linkOrChange(isChange: false);
                if (v == 'change') _linkOrChange(isChange: true);
                if (v == 'remove') _remove();
              },
              itemBuilder: (context) => [
                if (!linked)
                  PopupMenuItem(
                      value: 'link', child: Text(l10n.linkGoogleAccount)),
                if (linked) ...[
                  PopupMenuItem(
                      value: 'change', child: Text(l10n.changeGoogleAccount)),
                  PopupMenuItem(
                      value: 'remove', child: Text(l10n.removeGoogleAccount)),
                ],
              ],
            ),
    );
  }
}
