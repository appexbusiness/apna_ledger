import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/app_settings_controller.dart';

/// First-run screen: choose language + theme on a single page. Skippable.
/// Both choices apply live so the user sees the effect immediately.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _languages = <String, String>{
    'en': 'English',
    'hi': 'हिन्दी',
    'gu': 'ગુજરાતી',
    'bn': 'বাংলা',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
  };

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
    if (context.mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () => _finish(context, ref),
                      child: Text(l10n.skip),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.personalise, style: text.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    l10n.personaliseSubtitle,
                    style: text.bodyMedium?.copyWith(color: context.semantic.muted),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView(
                      children: [
                        Text(l10n.chooseLanguage, style: text.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final entry in _languages.entries)
                              _ChoiceChip(
                                label: entry.value,
                                selected:
                                    settings.locale.languageCode == entry.key,
                                onTap: () => ref
                                    .read(appSettingsProvider.notifier)
                                    .setLocale(Locale(entry.key)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(l10n.chooseTheme, style: text.titleMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ThemeCard(
                              label: l10n.lightTheme,
                              icon: Icons.light_mode_outlined,
                              selected: settings.themeMode == ThemeMode.light,
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 12),
                            _ThemeCard(
                              label: l10n.darkTheme,
                              icon: Icons.dark_mode_outlined,
                              selected: settings.themeMode == ThemeMode.dark,
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeMode(ThemeMode.dark),
                            ),
                            const SizedBox(width: 12),
                            _ThemeCard(
                              label: l10n.systemTheme,
                              icon: Icons.brightness_auto_outlined,
                              selected: settings.themeMode == ThemeMode.system,
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeMode(ThemeMode.system),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: l10n.getStarted,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => _finish(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.10)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : context.semantic.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? scheme.primary : context.semantic.muted),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
