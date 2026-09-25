import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/app_settings_controller.dart';

/// First-run screen: choose language + theme on a single page. Skippable.
/// Both choices apply live so the user sees the effect immediately.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _languages = <String, (String, String)>{
    'en': ('English', 'Aa'),
    'hi': ('हिन्दी', 'अ'),
    'gu': ('ગુજરાતી', 'અ'),
    'bn': ('বাংলা', 'অ'),
    'te': ('తెలుగు', 'అ'),
    'ta': ('தமிழ்', 'அ'),
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
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        const BrandLogo(size: 40, halo: false),
                        const SizedBox(width: 8),
                        Text(l10n.appName, style: text.titleMedium),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _finish(context, ref),
                          child: Text(l10n.skip),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      children: [
                        const Entrance(
                          child: Center(
                            child: FinIllustration(
                              glyph: FinGlyph.wallet,
                              size: 170,
                            ),
                          ),
                        ),
                        Entrance(
                          index: 1,
                          child: Text(
                            l10n.personalise,
                            textAlign: TextAlign.center,
                            style: text.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Entrance(
                          index: 2,
                          child: Text(
                            l10n.personaliseSubtitle,
                            textAlign: TextAlign.center,
                            style: text.bodyMedium
                                ?.copyWith(color: context.semantic.muted),
                          ),
                        ),
                        const SizedBox(height: 26),
                        GroupLabel(l10n.chooseLanguage),
                        LayoutBuilder(
                          builder: (context, c) {
                            final w = (c.maxWidth - 20) / 3;
                            var i = 0;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final e in _languages.entries)
                                  SizedBox(
                                    width: w,
                                    child: Entrance(
                                      index: 3 + i++,
                                      child: _LanguageTile(
                                        label: e.value.$1,
                                        glyph: e.value.$2,
                                        selected: settings.locale.languageCode ==
                                            e.key,
                                        onTap: () => ref
                                            .read(appSettingsProvider.notifier)
                                            .setLocale(Locale(e.key)),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        GroupLabel(l10n.chooseTheme),
                        Row(
                          children: [
                            for (final (i, m) in const [
                              ThemeMode.light,
                              ThemeMode.dark,
                              ThemeMode.system,
                            ].indexed) ...[
                              if (i > 0) const SizedBox(width: 10),
                              Expanded(
                                child: Entrance(
                                  index: 9 + i,
                                  child: _ThemeCard(
                                    mode: m,
                                    label: switch (m) {
                                      ThemeMode.light => l10n.lightTheme,
                                      ThemeMode.dark => l10n.darkTheme,
                                      ThemeMode.system => l10n.systemTheme,
                                    },
                                    selected: settings.themeMode == m,
                                    onTap: () => ref
                                        .read(appSettingsProvider.notifier)
                                        .setThemeMode(m),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: AppButton(
                      label: l10n.getStarted,
                      icon: Icons.arrow_forward_rounded,
                      variant: AppButtonVariant.gold,
                      onPressed: () => _finish(context, ref),
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
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.glyph,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    final s = context.surfaces;
    return Pressable(
      onTap: () {
        AppHaptics.select();
        onTap();
      },
      haptic: false,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        height: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? c.withValues(alpha: s.isDark ? 0.2 : 0.1) : s.card,
          border: Border.all(
            color: selected ? c : context.semantic.border,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected ? AppSurfaces.glow(c, strength: 0.4) : s.elevation(0.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: AppMotion.medium,
              curve: AppMotion.bouncy,
              child: Text(
                glyph,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: selected ? c : context.semantic.muted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mini phone preview of the theme, so the choice is visual.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    Widget screen(bool dark) => Container(
          color: dark ? AppColors.darkBg : AppColors.lightBg,
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Container(
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [AppColors.heroTop, AppColors.heroBottom],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              for (var i = 0; i < 3; i++)
                Container(
                  height: 9,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkCardSolid : Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        );

    return Pressable(
      onTap: () {
        AppHaptics.select();
        onTap();
      },
      haptic: false,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: context.surfaces.card,
          border: Border.all(
            color: selected ? c : context.semantic.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? AppSurfaces.glow(c, strength: 0.5)
              : context.surfaces.elevation(0.4),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 0.8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: switch (mode) {
                  ThemeMode.light => screen(false),
                  ThemeMode.dark => screen(true),
                  ThemeMode.system => Row(
                      children: [
                        Expanded(child: screen(false)),
                        Expanded(child: screen(true)),
                      ],
                    ),
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey(selected),
                    size: 16,
                    color: selected ? c : context.semantic.muted,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
