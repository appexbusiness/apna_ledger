import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/env_config.dart';
import '../../../core/config/flavor.dart';
import '../../../core/design/design.dart';
import '../../../core/error/failure.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_links.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pin_input.dart';
import '../../../core/widgets/powered_by.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../auth/presentation/providers/google_auth.dart';
import 'app_settings_controller.dart';
import 'pages/edit_profile_page.dart';
import 'pages/info_pages.dart';
import 'security_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const languages = <String, String>{
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
    var i = 0;
    Widget step(Widget child) => Entrance(index: i++, child: child);

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 150),
                children: [
                  ScreenHeader(title: l10n.settings),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!EnvConfig.instance.flavor.isProduction) ...[
                          step(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.semantic.loanGiven
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.science_rounded,
                                        size: 16,
                                        color: context.semantic.loanGiven,),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Environment: ${EnvConfig.instance.flavor.label}',
                                      style: TextStyle(
                                        color: context.semantic.loanGiven,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        step(const _ProfileHero()),
                        const SizedBox(height: 22),

                        // ---- Preferences ----
                        GroupLabel('${l10n.language} · ${l10n.theme}'),
                        step(
                          _Group(
                            children: [
                              _SettingRow(
                                glyph: FinGlyph.language,
                                title: l10n.language,
                                subtitle:
                                    languages[settings.locale.languageCode],
                                onTap: () => _pickLanguage(context, ref),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon3D(
                                          glyph: FinGlyph.theme,
                                          size: 40,
                                          style: Icon3DStyle.soft,
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          l10n.theme,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SegmentedPills<ThemeMode>(
                                      options: const [
                                        ThemeMode.light,
                                        ThemeMode.dark,
                                        ThemeMode.system,
                                      ],
                                      value: settings.themeMode,
                                      labels: (m) => switch (m) {
                                        ThemeMode.light => l10n.lightTheme,
                                        ThemeMode.dark => l10n.darkTheme,
                                        ThemeMode.system => l10n.systemTheme,
                                      },
                                      icons: (m) => switch (m) {
                                        ThemeMode.light =>
                                          Icons.light_mode_rounded,
                                        ThemeMode.dark =>
                                          Icons.dark_mode_rounded,
                                        ThemeMode.system =>
                                          Icons.brightness_auto_rounded,
                                      },
                                      onChanged: (m) => ref
                                          .read(appSettingsProvider.notifier)
                                          .setThemeMode(m),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ---- Security ----
                        GroupLabel(l10n.security),
                        step(
                          const _Group(
                            children: [
                              _AppLockTile(),
                              _PinTile(),
                              _ChangePasswordTile(),
                              _GoogleAccountTile(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ---- Help & legal ----
                        const GroupLabel('Help & legal'),
                        step(
                          _Group(
                            children: [
                              _SettingRow(
                                glyph: FinGlyph.help,
                                title: l10n.help,
                                subtitle: l10n.helpEmail,
                                onTap: () => openUrl(
                                  'mailto:${l10n.helpEmail}?subject=Apna%20Ledger%20Support',
                                ),
                              ),
                              _SettingRow(
                                glyph: FinGlyph.learn,
                                title: l10n.howToUse,
                                onTap: () =>
                                    context.push('/dashboard/settings/how-to'),
                              ),
                              _SettingRow(
                                glyph: FinGlyph.share,
                                title: l10n.shareApp,
                                onTap: () => Share.share(
                                  'I track every paisa with ${l10n.appName} — simple, private hisaab in your language. Try it!',
                                  subject: l10n.appName,
                                ),
                              ),
                              _SettingRow(
                                glyph: FinGlyph.privacy,
                                title: l10n.privacyPolicy,
                                onTap: () => showInfoSheet(
                                  context,
                                  title: l10n.privacyPolicy,
                                  glyph: FinGlyph.privacy,
                                  children: privacyPolicyChildren(),
                                ),
                              ),
                              _SettingRow(
                                glyph: FinGlyph.legal,
                                title: l10n.termsConditions,
                                onTap: () => showInfoSheet(
                                  context,
                                  title: l10n.termsConditions,
                                  glyph: FinGlyph.legal,
                                  children: termsChildren(),
                                ),
                              ),
                              _SettingRow(
                                glyph: FinGlyph.info,
                                title: l10n.aboutApp,
                                onTap: () => showInfoSheet(
                                  context,
                                  title: l10n.aboutApp,
                                  glyph: FinGlyph.info,
                                  children: aboutChildren(context, l10n),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),

                        // ---- Logout ----
                        step(
                          AppButton(
                            label: l10n.logout,
                            icon: Icons.logout_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => _confirmLogout(context, ref),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Center(child: PoweredByAppex()),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            '${l10n.appName} · v1.0.0',
                            style: TextStyle(
                              color: context.semantic.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(appSettingsProvider).locale.languageCode;
    final code = await showChoiceSheet<String>(
      context,
      title: l10n.chooseLanguage,
      glyph: FinGlyph.language,
      selected: current,
      options: [
        for (final e in languages.entries)
          ChoiceOption(
            value: e.key,
            label: e.value,
            icon: Icons.translate_rounded,
            color: AppColors.info,
          ),
      ],
    );
    if (code != null) {
      await ref.read(appSettingsProvider.notifier).setLocale(Locale(code));
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showAppConfirm(
      context,
      icon: Icons.logout_rounded,
      title: l10n.logout,
      message: '${l10n.logout}?',
      confirmLabel: l10n.logout,
      danger: true,
    );
    if (ok) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

/// Profile card on the navy panel: gold-ringed avatar, name, phone, email
/// status and an edit action.
class _ProfileHero extends ConsumerWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider);
    final name = user?.displayName ?? '';
    final verified =
        (user?.email ?? '').isNotEmpty && (user?.emailVerified ?? false);

    return HeroPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentSoft, AppColors.goldDeep],
              ),
              boxShadow: AppSurfaces.glow(AppColors.accent),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+91 ${user?.phone ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 14, color: Color(0xFF6EE7A8),),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user!.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6EE7A8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconOrb(
            icon: Icons.edit_rounded,
            onDark: true,
            tooltip: l10n.editProfile,
            onTap: () => showEditProfileSheet(context),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Surface3D(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                indent: 66,
                endIndent: 14,
                color: context.semantic.border.withValues(alpha: 0.6),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.glyph,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
  });

  final FinGlyph glyph;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            leading ??
                Icon3D(glyph: glyph, size: 40, style: Icon3DStyle.soft),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.semantic.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: context.semantic.muted,),
          ],
        ),
      ),
    );
  }
}

class _PinTile extends ConsumerWidget {
  const _PinTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasPin = ref.watch(pinProvider);
    return _SettingRow(
      glyph: FinGlyph.pin,
      title: l10n.setPin,
      subtitle: l10n.pinSubtitle,
      trailing: hasPin
          ? TextButton(
              onPressed: () async {
                await ref.read(pinProvider.notifier).clear();
                if (context.mounted) {
                  Toaster.of(context).info(l10n.removePin);
                }
              },
              child: Text(
                l10n.removePin,
                style: TextStyle(color: context.semantic.expense),
              ),
            )
          : null,
      onTap: () => _setPin(context, ref),
    );
  }

  Future<void> _setPin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    final pin1 = TextEditingController();
    final pin2 = TextEditingController();
    var shake = 0;
    String? error;
    final pin = await showAppSheet<String>(
      context,
      title: l10n.setPin,
      subtitle: l10n.pinSubtitle,
      glyph: FinGlyph.pin,
      builder: (context, setSheet) {
        void submit() {
          final a = pin1.text.trim();
          final b = pin2.text.trim();
          if (a.length != 4 || b.length != 4) {
            setSheet(() => shake++);
            return;
          }
          if (a != b) {
            setSheet(() {
              error = l10n.pinMismatch;
              shake++;
              pin2.clear();
            });
            return;
          }
          Navigator.pop(context, a);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.enterPin,
                style: TextStyle(
                    color: context.semantic.muted,
                    fontWeight: FontWeight.w700,),),
            const SizedBox(height: 10),
            PinBoxes(controller: pin1, autofocus: true),
            const SizedBox(height: 20),
            Text(l10n.confirmPin,
                style: TextStyle(
                    color: context.semantic.muted,
                    fontWeight: FontWeight.w700,),),
            const SizedBox(height: 10),
            PinBoxes(
              controller: pin2,
              errorTrigger: shake,
              hasError: error != null,
              onChanged: (_) {
                if (error != null) setSheet(() => error = null);
              },
            ),
            AnimatedSize(
              duration: AppMotion.fast,
              child: error == null
                  ? const SizedBox(height: 20)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: context.semantic.expense,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            AppButton(
              label: l10n.save,
              icon: Icons.check_rounded,
              onPressed: submit,
            ),
          ],
        );
      },
    );
    if (pin == null) return;
    await ref.read(pinProvider.notifier).setPin(pin);
    toast.success(l10n.pinSet);
  }
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

    Future<void> onChanged(bool v) async {
      final toast = Toaster.of(context);
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
          toast.success(l10n.appLock);
          return;
        }
        final msg = switch (result.status) {
          BiometricStatus.notEnrolled => l10n.biometricNotEnrolled,
          BiometricStatus.lockedOut => l10n.biometricLockedOut,
          BiometricStatus.permissionDenied => l10n.biometricPermissionDenied,
          BiometricStatus.cancelled => null, // user backed out; no error
          _ => l10n.biometricUnavailable,
        };
        if (msg != null) toast.error(msg);
      } else if (hasPin) {
        await ref.read(appLockProvider.notifier).set(true);
      } else {
        toast.error(l10n.biometricUnavailable);
      }
    }

    return _SettingRow(
      glyph: FinGlyph.fingerprint,
      title: l10n.appLock,
      subtitle: l10n.appLockSubtitle,
      onTap: () => onChanged(!enabled),
      trailing: Switch.adaptive(value: enabled, onChanged: onChanged),
    );
  }
}

/// Settings → Security → Change Password. Requires the current password.
class _ChangePasswordTile extends ConsumerWidget {
  const _ChangePasswordTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SettingRow(
      glyph: FinGlyph.key,
      title: l10n.changePassword,
      onTap: () => _run(context, ref),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    final oldPwd = TextEditingController();
    final newPwd = TextEditingController();
    final confirmPwd = TextEditingController();
    String? error;
    final ok = await showAppSheet<bool>(
      context,
      title: l10n.changePassword,
      glyph: FinGlyph.key,
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: oldPwd,
            label: l10n.currentPassword,
            icon: Icons.lock_rounded,
            obscure: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: newPwd,
            label: l10n.newPassword,
            icon: Icons.lock_reset_rounded,
            obscure: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: confirmPwd,
            label: l10n.confirmPassword,
            icon: Icons.lock_reset_rounded,
            obscure: true,
            errorText: error,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: l10n.save,
            icon: Icons.check_rounded,
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
      toast.success(l10n.passwordUpdated);
    } on AppFailure {
      toast.error(l10n.wrongPassword);
    } catch (_) {
      toast.error(l10n.somethingWrong);
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
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    final service = ref.read(googleSignInServiceProvider);
    final result =
        isChange ? await service.pickDifferent() : await service.pick();
    if (!mounted) return;
    if (result.cancelled) {
      setState(() => _busy = false);
      return;
    }
    if (result.error != null) {
      setState(() => _busy = false);
      toast.error(result.error!);
      return;
    }
    final notifier = ref.read(authControllerProvider.notifier);
    final err = isChange
        ? await notifier.changeGoogleEmail(
            result.account?.email ?? '',
            result.account?.name,
          )
        : await notifier.linkGoogleEmail(
            result.account?.email ?? '',
            result.account?.name,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (err) {
      case null:
        toast.success(
          isChange ? l10n.googleAccountChanged : l10n.emailVerifiedDone,
        );
      case 'emailLinkedElsewhere':
        toast.error(l10n.emailLinkedElsewhere);
      case 'emailMismatchProfile':
        toast.error(l10n.googleEmailMismatch);
      default:
        toast.error(l10n.somethingWrong);
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
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
    switch (err) {
      case null:
        toast.success(l10n.googleAccountRemoved);
      case 'setPasswordFirst':
        toast.error(l10n.setPasswordFirstToRemoveGoogle);
      default:
        toast.error(l10n.somethingWrong);
    }
  }

  Future<void> _actions(bool linked) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showChoiceSheet<String>(
      context,
      title: l10n.googleAccount,
      options: [
        if (!linked)
          ChoiceOption(
            value: 'link',
            label: l10n.linkGoogleAccount,
            icon: Icons.link_rounded,
            color: AppColors.info,
          ),
        if (linked) ...[
          ChoiceOption(
            value: 'change',
            label: l10n.changeGoogleAccount,
            icon: Icons.swap_horiz_rounded,
            color: AppColors.info,
          ),
          ChoiceOption(
            value: 'remove',
            label: l10n.removeGoogleAccount,
            icon: Icons.link_off_rounded,
            destructive: true,
          ),
        ],
      ],
    );
    if (choice == 'link') _linkOrChange(isChange: false);
    if (choice == 'change') _linkOrChange(isChange: true);
    if (choice == 'remove') _remove();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider);
    final linked =
        (user?.email ?? '').isNotEmpty && (user?.emailVerified ?? false);

    return _SettingRow(
      glyph: FinGlyph.email,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.surfaces.surface2,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset('assets/branding/google_g.svg',
            height: 20, width: 20,),
      ),
      title: l10n.googleAccount,
      subtitle: linked ? user!.email! : l10n.googleAccountNotLinked,
      onTap: _busy ? null : () => _actions(linked),
      trailing: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}
