import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/presentation/new_txn_args.dart';

/// In-memory calculator history (kept for the session).
final calcHistoryProvider = StateProvider<List<String>>((ref) => []);

/// A quick calculator with everyday helpers (split a bill, apply a discount)
/// plus a clear basic pad. Any result can be sent straight into Add Transaction.
class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.calculator),
          actions: [
            IconButton(
              tooltip: l10n.notes,
              onPressed: () => context.push('/dashboard/notes'),
              icon: const Icon(Icons.sticky_note_2_outlined),
            ),
            IconButton(
              tooltip: l10n.calcHistory,
              onPressed: () => _showHistory(context, ref),
              icon: const Icon(Icons.history_rounded),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.calculator),
              Tab(text: l10n.splitBill),
              Tab(text: l10n.discountCalc),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _BasicPad(),
              _SplitTab(),
              _DiscountTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final history = ref.watch(calcHistoryProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.calcHistory,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      if (history.isNotEmpty)
                        TextButton(
                          onPressed: () => ref
                              .read(calcHistoryProvider.notifier)
                              .state = [],
                          child: Text(l10n.clearHistory),
                        ),
                    ],
                  ),
                ),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(l10n.calcHistoryEmpty,
                        style: TextStyle(color: context.semantic.muted)),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final h in history)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.calculate_outlined),
                            title: Text(h),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shows a computed amount with an "add as transaction" shortcut.
class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: context.semantic.muted)),
            const SizedBox(height: 4),
            Text(
              Formatters.moneyWhole(amount),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: l10n.addAsTransaction,
              icon: Icons.add_rounded,
              onPressed: amount <= 0
                  ? null
                  : () => context.push('/dashboard/transaction',
                      extra: NewTxnArgs(amount: amount)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitTab extends StatefulWidget {
  const _SplitTab();
  @override
  State<_SplitTab> createState() => _SplitTabState();
}

class _SplitTabState extends State<_SplitTab> {
  final _total = TextEditingController();
  final _members = TextEditingController(text: '2');

  double get _perPerson {
    final total = double.tryParse(_total.text.trim()) ?? 0;
    final n = int.tryParse(_members.text.trim()) ?? 0;
    if (n <= 0) return 0;
    return total / n;
  }

  @override
  void dispose() {
    _total.dispose();
    _members.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.splitBill, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Turf, trip, hostel, dinner — split evenly in seconds.',
            style: TextStyle(color: context.semantic.muted)),
        const SizedBox(height: 20),
        AppTextField(
          controller: _total,
          label: l10n.totalAmount,
          prefixText: '₹ ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _members,
          label: l10n.numMembers,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        _ResultBar(label: l10n.perPerson, amount: _perPerson),
      ],
    );
  }
}

class _DiscountTab extends StatefulWidget {
  const _DiscountTab();
  @override
  State<_DiscountTab> createState() => _DiscountTabState();
}

class _DiscountTabState extends State<_DiscountTab> {
  final _amount = TextEditingController();
  final _pct = TextEditingController(text: '10');

  double get _finalAmount {
    final amt = double.tryParse(_amount.text.trim()) ?? 0;
    final pct = double.tryParse(_pct.text.trim()) ?? 0;
    return amt - (amt * pct / 100);
  }

  double get _saved {
    final amt = double.tryParse(_amount.text.trim()) ?? 0;
    final pct = double.tryParse(_pct.text.trim()) ?? 0;
    return amt * pct / 100;
  }

  @override
  void dispose() {
    _amount.dispose();
    _pct.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.discountCalc,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        AppTextField(
          controller: _amount,
          label: l10n.totalAmount,
          prefixText: '₹ ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _pct,
          label: l10n.discountPercent,
          suffix: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('%'),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('You save ${Formatters.moneyWhole(_saved)}',
              style: TextStyle(color: context.semantic.income)),
        ),
        const SizedBox(height: 20),
        _ResultBar(
            label: l10n.result, amount: _finalAmount < 0 ? 0 : _finalAmount),
      ],
    );
  }
}

/// A clear sequential calculator: the expression is shown on top, the current
/// value/result below. Left-to-right evaluation (pocket-calculator style).
class _BasicPad extends ConsumerStatefulWidget {
  const _BasicPad();
  @override
  ConsumerState<_BasicPad> createState() => _BasicPadState();
}

class _BasicPadState extends ConsumerState<_BasicPad> {
  final List<String> _tokens = []; // numbers + operators already committed
  String _display = '0';
  bool _fresh = true;
  String? _result; // set after '='

  String get _expression =>
      (_tokens.join(' ') + (_fresh && _tokens.isNotEmpty ? '' : ' $_display'))
          .trim();

  double _evaluate(List<String> tokens) {
    if (tokens.isEmpty) return 0;
    var acc = double.tryParse(tokens.first) ?? 0;
    for (var i = 1; i < tokens.length - 1; i += 2) {
      final op = tokens[i];
      final next = double.tryParse(tokens[i + 1]) ?? 0;
      switch (op) {
        case '+':
          acc += next;
          break;
        case '−':
          acc -= next;
          break;
        case '×':
          acc *= next;
          break;
        case '÷':
          acc = next == 0 ? 0 : acc / next;
          break;
      }
    }
    return acc;
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  void _tap(String k) {
    setState(() {
      _result = null;
      if (k == 'C') {
        _tokens.clear();
        _display = '0';
        _fresh = true;
      } else if (k == '⌫') {
        if (_display.length <= 1) {
          _display = '0';
          _fresh = true;
        } else {
          _display = _display.substring(0, _display.length - 1);
        }
      } else if (k == '+' || k == '−' || k == '×' || k == '÷') {
        _tokens
          ..add(_display)
          ..add(k);
        _fresh = true;
      } else if (k == '=') {
        final all = [..._tokens, _display];
        final value = _evaluate(all);
        final expr = all.join(' ');
        _result = _trim(value);
        _display = _result!;
        _tokens.clear();
        _fresh = true;
        if (all.length >= 3) {
          ref.read(calcHistoryProvider.notifier).update(
              (h) => ['$expr = ${_trim(value)}', ...h].take(50).toList());
        }
      } else if (k == '.') {
        if (_fresh) {
          _display = '0.';
          _fresh = false;
        } else if (!_display.contains('.')) {
          _display += '.';
        }
      } else {
        if (_fresh || _display == '0') {
          _display = k;
          _fresh = false;
        } else {
          _display += k;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_display) ?? 0;
    const keys = [
      ['C', '⌫', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['.', '0', '='],
    ];
    return Column(
      children: [
        // Expression + result panel
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _tokens.isEmpty && _result == null ? ' ' : _expression,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.semantic.muted, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                _result != null ? '= $_display' : _display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (final row in keys)
                  Expanded(
                    child: Row(
                      children: [
                        for (final k in row)
                          _Key(
                            label: k,
                            onTap: () => _tap(k),
                            accent: ['÷', '×', '−', '+', '='].contains(k),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: l10n.addAsTransaction,
            icon: Icons.add_rounded,
            onPressed: amount <= 0
                ? null
                : () => context.push('/dashboard/transaction',
                    extra: NewTxnArgs(amount: amount)),
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.accent = false});
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: accent
              ? scheme.primary.withValues(alpha: 0.12)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: accent ? scheme.primary : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Savings goals: set targets, add money as you go, and track progress. Helps
/// users take control of income by earmarking savings.
