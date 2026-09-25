import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/savings_goal.dart';
import 'goals_providers.dart';

/// Savings goals — dedicated screen (opened from the Home tools row).
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savingsGoals)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fabGoal',
        onPressed: () => _addGoalSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addGoal),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                Text(l10n.salaryTip,
                    style: TextStyle(
                        color: context.semantic.muted, fontSize: 12.5)),
                const SizedBox(height: 12),
                if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.savings_outlined,
                            size: 56, color: context.semantic.muted),
                        const SizedBox(height: 12),
                        Text(l10n.noGoals,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.semantic.muted)),
                      ],
                    ),
                  )
                else
                  for (final g in goals) _GoalCard(goal: g),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline,
                        color: context.semantic.expense, size: 20),
                    onPressed: () async {
                      final ok = await showAppConfirm(context,
                          icon: Icons.delete_outline,
                          title: l10n.delete,
                          message: goal.name,
                          confirmLabel: l10n.delete,
                          danger: true);
                      if (ok) {
                        await ref.read(goalsProvider.notifier).remove(goal.id);
                      }
                    },
                  ),
                ],
              ),
              if (goal.dueDate != null)
                Text('${l10n.dueDate}: ${Formatters.fullDate(goal.dueDate!)}',
                    style: TextStyle(
                        color: context.semantic.muted, fontSize: 11.5)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: goal.progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor:
                        context.semantic.income.withValues(alpha: 0.12),
                    valueColor:
                        AlwaysStoppedAnimation(context.semantic.income),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${Formatters.moneySmart(goal.saved)} / ${Formatters.moneySmart(goal.target)}',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    goal.reached
                        ? l10n.goalReached
                        : '${Formatters.moneySmart(goal.remaining)} ${l10n.remaining}',
                    style: TextStyle(
                        color: goal.reached
                            ? context.semantic.income
                            : context.semantic.muted,
                        fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _addMoneySheet(context, ref, goal.id),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addMoney),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _addGoalSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final name = TextEditingController();
  final target = TextEditingController();
  DateTime? due;
  await showAppSheet<void>(
    context,
    title: l10n.addGoal,
    builder: (context, setSheet) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(controller: name, label: l10n.goalName),
        const SizedBox(height: 12),
        AppTextField(
          controller: target,
          label: l10n.targetAmount,
          prefixText: '₹ ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) setSheet(() => due = picked);
          },
          icon: const Icon(Icons.event, size: 18),
          label: Text(due == null
              ? l10n.dueDate
              : Formatters.fullDate(due!)),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: l10n.save,
          icon: Icons.check_rounded,
          onPressed: () {
            final t = double.tryParse(target.text.trim()) ?? 0;
            if (name.text.trim().isEmpty || t <= 0 || t > Validators.maxAmount) {
              return;
            }
            ref
                .read(goalsProvider.notifier)
                .add(name.text.trim(), t, dueDate: due);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

Future<void> _addMoneySheet(
    BuildContext context, WidgetRef ref, String id) async {
  final l10n = AppLocalizations.of(context);
  final amount = TextEditingController();
  await showAppSheet<void>(
    context,
    title: l10n.addMoney,
    builder: (context, setSheet) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: amount,
          label: l10n.amount,
          prefixText: '₹ ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
        ),
        const SizedBox(height: 18),
        AppButton(
          label: l10n.save,
          icon: Icons.check_rounded,
          onPressed: () {
            final a = double.tryParse(amount.text.trim()) ?? 0;
            if (a > 0 && a <= Validators.maxAmount) {
              ref.read(goalsProvider.notifier).addSaved(id, a);
            }
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
