import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/savings_goal.dart';
import 'goals_providers.dart';

const _pink = Color(0xFFEC4899);

/// Savings goals — dedicated screen (opened from the Home tools dock).
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goals = ref.watch(goalsProvider);
    final saved = goals.fold<double>(0, (s, g) => s + g.saved);
    final target = goals.fold<double>(0, (s, g) => s + g.target);

    return Scaffold(
      floatingActionButton: AppButton(
        label: l10n.addGoal,
        icon: Icons.add_rounded,
        color: _pink,
        expand: false,
        onPressed: () => _addGoalSheet(context, ref),
      ),
      body: AmbientBackground(
        tint: _pink,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 110),
                children: [
                  ScreenHeader(
                    title: l10n.savingsGoals,
                    onBack: () => context.pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (goals.isNotEmpty) ...[
                          Entrance(
                            child: _TotalHero(saved: saved, target: target),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Entrance(
                          index: 1,
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_rounded,
                                  size: 16, color: AppColors.accent,),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.salaryTip,
                                  style: TextStyle(
                                    color: context.semantic.muted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (goals.isEmpty)
                          EmptyState(
                            glyph: FinGlyph.goals,
                            title: l10n.noGoals,
                            actionLabel: l10n.addGoal,
                            onAction: () => _addGoalSheet(context, ref),
                          )
                        else
                          for (var i = 0; i < goals.length; i++)
                            Entrance(
                              index: i + 2,
                              child: _GoalCard(goal: goals[i]),
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

class _TotalHero extends StatelessWidget {
  const _TotalHero({required this.saved, required this.target});
  final double saved;
  final double target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
    return HeroPanel(
      accentGlow: _pink,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.saved,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUp(
                    value: saved,
                    format: Formatters.moneySmart,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '/ ${Formatters.moneySmart(target)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          RingProgress(
            value: p,
            color: _pink,
            size: 84,
            child: Text(
              '${(p * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
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
    final color = goal.reached ? context.semantic.income : _pink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface3D(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RingProgress(
                  value: goal.progress,
                  color: color,
                  size: 64,
                  stroke: 8,
                  child: goal.reached
                      ? Icon(Icons.emoji_events_rounded, color: color, size: 26)
                      : Text(
                          '${(goal.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: color,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (goal.dueDate != null)
                        Text(
                          '${l10n.dueDate}: ${Formatters.fullDate(goal.dueDate!)}',
                          style: TextStyle(
                            color: context.semantic.muted,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${Formatters.moneySmart(goal.saved)} / ${Formatters.moneySmart(goal.target)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconOrb(
                  icon: Icons.delete_rounded,
                  size: 38,
                  color: context.semantic.expense,
                  tooltip: l10n.delete,
                  onTap: () async {
                    final toast = Toaster.of(context);
                    final ok = await showAppConfirm(
                      context,
                      icon: Icons.delete_rounded,
                      title: l10n.delete,
                      message: goal.name,
                      confirmLabel: l10n.delete,
                      danger: true,
                    );
                    if (ok) {
                      await ref.read(goalsProvider.notifier).remove(goal.id);
                      toast.success(l10n.deletedToast);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlowBar(value: goal.progress, color: color),
            const SizedBox(height: 8),
            Text(
              goal.reached
                  ? l10n.goalReached
                  : '${Formatters.moneySmart(goal.remaining)} ${l10n.remaining}',
              style: TextStyle(
                color: goal.reached ? color : context.semantic.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: l10n.addMoney,
              icon: Icons.add_rounded,
              variant: AppButtonVariant.secondary,
              height: 50,
              onPressed: () => _addMoneySheet(context, ref, goal),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _addGoalSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final toast = Toaster.of(context);
  final name = TextEditingController();
  final target = TextEditingController();
  DateTime? due;
  var shake = 0;
  final added = await showAppSheet<bool>(
    context,
    title: l10n.addGoal,
    glyph: FinGlyph.goals,
    builder: (context, setSheet) => Shake(
      trigger: shake,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: name,
            label: l10n.goalName,
            icon: Icons.flag_rounded,
            accent: _pink,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: target,
            label: l10n.targetAmount,
            prefixText: '₹ ',
            icon: Icons.savings_rounded,
            accent: _pink,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: Validators.amount,
          ),
          const SizedBox(height: 12),
          AppPickerField(
            label: l10n.dueDate,
            value: due == null ? null : Formatters.fullDate(due!),
            icon: Icons.event_rounded,
            accent: _pink,
            onTap: () async {
              final picked = await showAppDatePicker(
                context,
                initial: DateTime.now().add(const Duration(days: 90)),
                first: DateTime.now(),
                last: DateTime(2100),
                title: l10n.dueDate,
                accent: _pink,
              );
              if (picked != null) setSheet(() => due = picked);
            },
          ),
          const SizedBox(height: 18),
          AppButton(
            label: l10n.save,
            icon: Icons.check_rounded,
            color: _pink,
            onPressed: () {
              final t = double.tryParse(target.text.trim()) ?? 0;
              if (name.text.trim().isEmpty ||
                  t <= 0 ||
                  t > Validators.maxAmount) {
                setSheet(() => shake++);
                return;
              }
              ref
                  .read(goalsProvider.notifier)
                  .add(name.text.trim(), t, dueDate: due);
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    ),
  );
  if (added == true) toast.success(l10n.savedToast);
}

Future<void> _addMoneySheet(
  BuildContext context,
  WidgetRef ref,
  SavingsGoal goal,
) async {
  final l10n = AppLocalizations.of(context);
  final amount = TextEditingController();
  var shake = 0;
  final added = await showAppSheet<double>(
    context,
    title: l10n.addMoney,
    subtitle: goal.name,
    glyph: FinGlyph.goals,
    builder: (context, setSheet) => Shake(
      trigger: shake,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: amount,
            label: l10n.amount,
            prefixText: '₹ ',
            icon: Icons.payments_rounded,
            accent: _pink,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: Validators.amount,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in const [500.0, 1000.0, 5000.0])
                TagChip(
                  label: Formatters.moneyWhole(v),
                  color: _pink,
                  selected: false,
                  onTap: () => setSheet(() => amount.text = v.toStringAsFixed(0)),
                ),
              if (goal.remaining > 0)
                TagChip(
                  label:
                      '${Formatters.moneySmart(goal.remaining)} · ${l10n.remaining}',
                  icon: Icons.flag_rounded,
                  color: _pink,
                  selected: false,
                  onTap: () => setSheet(
                    () => amount.text = goal.remaining.toStringAsFixed(
                      goal.remaining == goal.remaining.roundToDouble() ? 0 : 2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          AppButton(
            label: l10n.save,
            icon: Icons.check_rounded,
            color: _pink,
            onPressed: () {
              final a = double.tryParse(amount.text.trim()) ?? 0;
              if (a <= 0 || a > Validators.maxAmount) {
                setSheet(() => shake++);
                return;
              }
              Navigator.pop(context, a);
            },
          ),
        ],
      ),
    ),
  );
  if (added == null) return;
  await ref.read(goalsProvider.notifier).addSaved(goal.id, added);
  if (!context.mounted) return;
  // Celebrate crossing the finish line.
  if (!goal.reached && goal.saved + added >= goal.target) {
    showSuccessBurst(context, message: l10n.goalReached);
  } else {
    Toaster.of(context).success(l10n.savedToast);
  }
}
