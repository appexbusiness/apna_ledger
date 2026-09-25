import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/india_states.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/date_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/google_auth.dart';

/// Opens Edit Profile as a bottom sheet — the app's standard pattern for
/// this kind of input — instead of a full pushed page.
Future<void> showEditProfileSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppSheet<void>(
    context,
    title: l10n.editProfile,
    glyph: FinGlyph.profile,
    builder: (context, setSheet) => const EditProfilePage(embedded: true),
  );
}

/// Searchable list of Indian states in a sheet. Returns the chosen state.
Future<String?> showStatePickerSheet(
  BuildContext context, {
  String? selected,
  String? title,
}) {
  final l10n = AppLocalizations.of(context);
  var query = '';
  final controller = TextEditingController();
  return showAppSheet<String>(
    context,
    title: title ?? l10n.state,
    glyph: FinGlyph.person,
    accent: AppColors.info,
    builder: (context, setSheet) {
      final list = IndiaStates.all
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: controller,
            hint: l10n.search,
            icon: Icons.search_rounded,
            onChanged: (v) => setSheet(() => query = v),
          ),
          const SizedBox(height: 12),
          for (final s in list)
            SheetOption(
              title: s,
              icon: Icons.location_on_rounded,
              color: AppColors.info,
              selected: s == selected,
              onTap: () => Navigator.pop(context, s),
            ),
        ],
      );
    },
  );
}

/// Edit the signed-in user's profile (name, email, date of birth, state).
/// [embedded]: true when shown inside [showEditProfileSheet] — renders
/// without its own Scaffold and pops the sheet on save instead of
/// navigating.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key, this.embedded = false});
  final bool embedded;

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _name = TextEditingController();
  DateTime? _dob;
  String? _state;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authControllerProvider);
    _name.text = u?.fullName ?? '';
    _dob = u?.dob;
    _state = u?.state;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppDatePicker(
      context,
      initial: _dob ?? DateTime(1995),
      first: DateTime(1920),
      last: DateTime.now(),
      title: l10n.dob,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickState() async {
    final picked = await showStatePickerSheet(context, selected: _state);
    if (picked != null) setState(() => _state = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _name.text.trim(),
            dob: _dob,
            state: _state,
          );
      toast.success(l10n.profileUpdated);
      if (widget.embedded) {
        navigator.pop();
      } else {
        // Deterministically return to Settings (works whether pushed or not).
        router.go('/dashboard/settings');
      }
    } catch (_) {
      toast.error(l10n.somethingWrong, retryLabel: l10n.retry, onRetry: _save);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider);
    final content = _buildFields(context, l10n, user);

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      );
    }

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  ScreenHeader(
                    title: l10n.editProfile,
                    onBack: () => context.go('/dashboard/settings'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: content,
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

  List<Widget> _buildFields(
    BuildContext context,
    AppLocalizations l10n,
    AppUser? user,
  ) {
    final email = user?.email ?? '';
    final verified = user?.emailVerified ?? false;
    var i = 0;
    Widget step(Widget w) => Entrance(index: i++, offset: 12, child: w);

    return [
      step(
        _InfoTile(
          glyph: FinGlyph.phone,
          title: '+91 ${user?.phone ?? ''}',
          subtitle: 'Phone number can’t be changed',
          trailing: Icon(Icons.lock_rounded,
              size: 18, color: context.semantic.muted,),
        ),
      ),
      const SizedBox(height: 14),
      step(
        AppTextField(
          controller: _name,
          label: l10n.name,
          icon: Icons.person_rounded,
          textCapitalization: TextCapitalization.words,
        ),
      ),
      const SizedBox(height: 14),
      step(
        _InfoTile(
          glyph: FinGlyph.email,
          title: email.isEmpty ? l10n.emailNotVerified : email,
          subtitle: email.isEmpty
              ? l10n.verifyEmailHint
              : (verified ? l10n.emailVerified : l10n.emailNotVerified),
          subtitleColor: verified ? context.semantic.income : null,
          trailing: verified
              ? Icon(Icons.verified_rounded, color: context.semantic.income)
              : null,
        ),
      ),
      if (!verified) ...[
        const SizedBox(height: 10),
        step(_EmailGoogleRow(email: user?.email, verified: verified)),
      ],
      const SizedBox(height: 14),
      step(
        AppPickerField(
          label: l10n.dob,
          value: _dob == null ? null : Formatters.fullDate(_dob!),
          icon: Icons.cake_rounded,
          leading: const Icon3D(
            glyph: FinGlyph.calendar,
            size: 38,
            style: Icon3DStyle.soft,
          ),
          onTap: _pickDob,
        ),
      ),
      const SizedBox(height: 14),
      step(
        AppPickerField(
          label: l10n.state,
          value: _state,
          icon: Icons.expand_more_rounded,
          leading: const Icon3D(
            icon: Icons.location_on_rounded,
            color: AppColors.info,
            size: 38,
            style: Icon3DStyle.soft,
          ),
          onTap: _pickState,
        ),
      ),
      const SizedBox(height: 24),
      step(
        AppButton(
          label: l10n.save,
          loading: _saving,
          icon: Icons.check_rounded,
          onPressed: _save,
        ),
      ),
      const SizedBox(height: 28),
      // Deliberately tucked away here (not on the main Settings screen) so
      // it isn't one accidental tap away.
      Center(
        child: TextButton.icon(
          onPressed: () => _confirmDeleteAccount(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: context.semantic.expense,
          ),
          icon: const Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(
            l10n.deleteAccount,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    ];
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.glyph,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.trailing,
  });

  final FinGlyph glyph;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaces.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Icon3D(glyph: glyph, size: 38, style: Icon3DStyle.soft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor ?? context.semantic.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Under the email card: "Verify email with Google". Opens a Google popup,
/// takes the email + name from the account, links it to this phone (1 email :
/// 1 phone) and marks it verified. No manual email typing, no email OTP.
class _EmailGoogleRow extends ConsumerStatefulWidget {
  const _EmailGoogleRow({required this.email, required this.verified});
  final String? email;
  final bool verified;

  @override
  ConsumerState<_EmailGoogleRow> createState() => _EmailGoogleRowState();
}

class _EmailGoogleRowState extends ConsumerState<_EmailGoogleRow> {
  bool _busy = false;

  Future<void> _linkWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    final result = await ref.read(googleSignInServiceProvider).pick();
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
    final err = await ref.read(authControllerProvider.notifier).linkGoogleEmail(
          result.account?.email ?? '',
          result.account?.name,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (err) {
      case null:
        toast.success(l10n.emailVerifiedDone);
      case 'emailLinkedElsewhere':
        toast.error(l10n.emailLinkedElsewhere);
      case 'emailMismatchProfile':
        toast.error(l10n.googleEmailMismatch);
      default:
        toast.error(l10n.somethingWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.verified) return const SizedBox.shrink();
    return Pressable(
      onTap: _busy ? null : _linkWithGoogle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surfaces.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.semantic.border),
          boxShadow: context.surfaces.elevation(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : SvgPicture.asset('assets/branding/google_g.svg',
                    height: 18, width: 18,),
            const SizedBox(width: 10),
            Text(
              l10n.verifyWithGoogle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final toast = Toaster.of(context);
  final password = TextEditingController();
  final ok = await showAppSheet<bool>(
    context,
    builder: (context, _) => ConfirmBody(
      icon: Icons.delete_forever_rounded,
      color: context.semantic.expense,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountBody,
      danger: true,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.deleteAccount,
      extra: AppTextField(
        controller: password,
        label: l10n.enterPassword,
        icon: Icons.lock_rounded,
        obscure: true,
        accent: context.semantic.expense,
      ),
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(authControllerProvider.notifier).deleteAccount(password.text);
    toast.success(l10n.accountDeleted);
    // Router auto-redirects to /login once auth state clears — no manual nav.
  } catch (_) {
    toast.error(l10n.wrongPassword);
  }
}
