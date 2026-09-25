import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/india_states.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
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
    builder: (context, setSheet) => const EditProfilePage(embedded: true),
  );
}

/// Edit the signed-in user's profile (name, email, date of birth, state).
/// [embedded]: true when shown inside [showEditProfileSheet] — renders
/// without its own Scaffold/AppBar and pops the sheet on save instead of
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _name.text.trim(),
            dob: _dob,
            state: _state,
          );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
      if (widget.embedded) {
        navigator.pop();
      } else {
        // Deterministically return to Settings (works whether pushed or not).
        router.go('/dashboard/settings');
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.somethingWrong)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider);
    final content = _buildFields(context, l10n, user);

    if (widget.embedded) {
      return Column(mainAxisSize: MainAxisSize.min, children: content);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: content,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields(
      BuildContext context, AppLocalizations l10n, AppUser? user) {
    return [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text('+91 ${user?.phone ?? ''}'),
                    subtitle: const Text('Phone number can’t be changed'),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(controller: _name, label: l10n.name),
                const SizedBox(height: 16),
                _FieldLabel(l10n.email),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text((user?.email ?? '').isEmpty
                        ? l10n.emailNotVerified
                        : user!.email!),
                    subtitle: Text(
                      (user?.email ?? '').isEmpty
                          ? l10n.verifyEmailHint
                          : (user!.emailVerified
                              ? l10n.emailVerified
                              : l10n.emailNotVerified),
                      style: TextStyle(
                          color: (user?.emailVerified ?? false)
                              ? context.semantic.income
                              : context.semantic.muted,
                          fontSize: 12),
                    ),
                    trailing: (user?.emailVerified ?? false)
                        ? Icon(Icons.verified_rounded,
                            color: context.semantic.income)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                _EmailGoogleRow(
                  email: user?.email,
                  verified: user?.emailVerified ?? false,
                ),
                const SizedBox(height: 16),
                _FieldLabel(l10n.dob),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dob == null ? '—' : Formatters.fullDate(_dob!),
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel(l10n.state),
                DropdownButtonFormField<String>(
                  value: _state,
                  isExpanded: true,
                  items: [
                    for (final s in IndiaStates.all)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(() => _state = v),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: l10n.save,
                  loading: _saving,
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 8),
                // Deliberately tucked away here (not on the main Settings
                // screen) so it isn't one accidental tap away.
                Center(
                  child: TextButton(
                    onPressed: () => _confirmDeleteAccount(context, ref),
                    style: TextButton.styleFrom(
                        foregroundColor: context.semantic.expense),
                    child: Text(l10n.deleteAccount,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
    ];
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

/// Under the email field: shows a verified badge, or a "Verify with Google"
/// button that confirms email ownership via a Google popup (no email OTP).

/// Under the email card: "Add / Verify email with Google". Opens a Google popup,
/// takes the email + name from the account, links it to this phone (1 email : 1
/// phone) and marks it verified. No manual email typing, no email OTP.
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
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await ref.read(googleSignInServiceProvider).pick();
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
    final err = await ref.read(authControllerProvider.notifier).linkGoogleEmail(
          result.account?.email ?? '',
          result.account?.name,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = switch (err) {
      null => l10n.emailVerifiedDone,
      'emailLinkedElsewhere' => l10n.emailLinkedElsewhere,
      'emailMismatchProfile' => l10n.googleEmailMismatch,
      _ => l10n.somethingWrong,
    };
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.verified) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _linkWithGoogle,
        icon: _busy
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : SvgPicture.asset('assets/branding/google_g.svg',
                height: 18, width: 18),
        label: Text(l10n.verifyWithGoogle),
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final password = TextEditingController();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.delete_forever_outlined,
          color: context.semantic.expense, size: 32),
      title: Text(l10n.deleteAccount),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteAccountBody,
                style: TextStyle(color: context.semantic.muted)),
            const SizedBox(height: 16),
            AppTextField(
              controller: password,
              label: l10n.enterPassword,
              obscure: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel)),
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: context.semantic.expense),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.deleteAccount),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(authControllerProvider.notifier).deleteAccount(password.text);
    messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    // Router auto-redirects to /login once auth state clears — no manual nav.
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.wrongPassword)));
  }
}
