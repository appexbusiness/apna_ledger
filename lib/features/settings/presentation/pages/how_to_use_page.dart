import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// A friendly, visual walkthrough of the app — a light "onboarding tour" the
/// user can revisit any time from Settings.
class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <_Step>[
      const _Step(
        icon: Icons.touch_app_outlined,
        color: AppColors.income,
        title: '1 · One-tap entry',
        body:
            'From Home, tap Income, Expense, Loan Given or Loan Taken. The colour tells you the type at a glance — green in, red out, amber lent, purple borrowed.',
      ),
      const _Step(
        icon: Icons.category_outlined,
        color: AppColors.primary,
        title: '2 · Organise with categories',
        body:
            'Group entries under categories and sub-categories — e.g. Business › Xerox Business. Create a new one right from the Add screen or the Categories tab.',
      ),
      const _Step(
        icon: Icons.handshake_outlined,
        color: AppColors.loanGiven,
        title: '3 · Track loans & people',
        body:
            'Recording a loan? Add the person’s name, interest % and a due date. People are just names you type — your contacts are never read.',
      ),
      const _Step(
        icon: Icons.repeat_rounded,
        color: AppColors.loanTaken,
        title: '4 · Set it and forget it',
        body:
            'Mark rent, EMIs or salary as Daily / Weekly / Monthly / Yearly. Review everything that repeats in the Recurring screen.',
      ),
      const _Step(
        icon: Icons.calculate_outlined,
        color: AppColors.info,
        title: '5 · Quick calculator',
        body:
            'Split a turf/trip/hostel bill, apply a discount, or do quick maths — then push the result straight into a transaction.',
      ),
      const _Step(
        icon: Icons.download_outlined,
        color: AppColors.warning,
        title: '6 · Your data is yours',
        body:
            'Export any view to CSV, or a single category’s ledger. Everything stays private — no bank details, no documents, ever.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.howToUse)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text('Welcome to ${l10n.appName} 👋',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('Here’s everything you can do, in six quick steps.',
                    style: TextStyle(color: context.semantic.muted)),
                const SizedBox(height: 20),
                for (final s in steps) _StepCard(step: s),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: const Text('Start keeping your hisaab'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(step.icon, color: step.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(step.body,
                      style: TextStyle(
                          color: context.semantic.muted,
                          height: 1.45,
                          fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
