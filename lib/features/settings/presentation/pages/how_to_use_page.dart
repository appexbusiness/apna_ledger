import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

/// A friendly, visual walkthrough of the app — a light "onboarding tour" the
/// user can revisit any time from Settings. Rendered as a 3D timeline.
class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  static const _steps = <(FinGlyph, String, String)>[
    (
      FinGlyph.income,
      '1 · One-tap entry',
      'From Home, tap Income, Expense, Loan Given or Loan Taken — or the gold + in the menu bar. The colour tells you the type at a glance — green in, red out, amber lent, purple borrowed.',
    ),
    (
      FinGlyph.categories,
      '2 · Organise with categories',
      'Group entries under categories and sub-categories — e.g. Business › Xerox Business. Create a new one right from the Add sheet or the Categories tab.',
    ),
    (
      FinGlyph.given,
      '3 · Track loans & people',
      'Recording a loan? Add the person’s name, interest % and a due date. People are just names you type — your contacts are never read.',
    ),
    (
      FinGlyph.recurring,
      '4 · Set it and forget it',
      'Mark rent, EMIs or salary as Daily / Weekly / Monthly / Yearly. Review everything that repeats in the Recurring screen.',
    ),
    (
      FinGlyph.calculator,
      '5 · Quick calculator',
      'Split a turf/trip/hostel bill, apply a discount, or do quick maths — then push the result straight into a transaction.',
    ),
    (
      FinGlyph.download,
      '6 · Your data is yours',
      'Export any view to PDF or CSV, or a single category’s ledger. Everything stays private — no bank details, no documents, ever.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  ScreenHeader(
                    title: l10n.howToUse,
                    onBack: () => context.pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Entrance(
                          child: Center(
                            child: FinIllustration(glyph: FinGlyph.learn),
                          ),
                        ),
                        Entrance(
                          index: 1,
                          child: Text(
                            'Welcome to ${l10n.appName} 👋',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Entrance(
                          index: 2,
                          child: Text(
                            'Here’s everything you can do, in six quick steps.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.semantic.muted),
                          ),
                        ),
                        const SizedBox(height: 22),
                        for (var i = 0; i < _steps.length; i++)
                          Entrance(
                            index: i + 3,
                            child: _StepTile(
                              glyph: _steps[i].$1,
                              title: _steps[i].$2,
                              body: _steps[i].$3,
                              last: i == _steps.length - 1,
                            ),
                          ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Start keeping your hisaab',
                          icon: Icons.rocket_launch_rounded,
                          onPressed: () => context.go('/dashboard'),
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
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.glyph,
    required this.title,
    required this.body,
    required this.last,
  });

  final FinGlyph glyph;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = glyph.spec.color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Icon3D(glyph: glyph, size: 46, coin: false),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.6),
                            color.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Surface3D(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        color: context.semantic.muted,
                        height: 1.45,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
