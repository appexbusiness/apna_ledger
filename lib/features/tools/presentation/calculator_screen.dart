import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/presentation/new_txn_args.dart';

/// In-memory calculator history (kept for the session).
final calcHistoryProvider = StateProvider<List<String>>((ref) => []);

/// A quick calculator with everyday helpers (split a bill, apply a discount)
/// plus a clear basic pad. Any result can be sent straight into Add
/// Transaction. Tabs swipe horizontally.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  late int _tab = widget.initialIndex;
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _tab = i);
    _pages.animateToPage(i, duration: AppMotion.medium, curve: AppMotion.enter);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AmbientBackground(
        tint: const Color(0xFF0EA5E9),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  ScreenHeader(
                    title: l10n.calculator,
                    onBack: () => context.pop(),
                    actions: [
                      IconOrb(
                        icon: Icons.sticky_note_2_rounded,
                        tooltip: l10n.notes,
                        onTap: () => context.push('/dashboard/notes'),
                      ),
                      IconOrb(
                        icon: Icons.history_rounded,
                        tooltip: l10n.calcHistory,
                        onTap: () => _showHistory(context),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SegmentedPills<int>(
                      options: const [0, 1, 2],
                      value: _tab,
                      labels: (i) => [
                        l10n.calculator,
                        l10n.splitBill,
                        l10n.discountCalc,
                      ][i],
                      onChanged: _go,
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _tab = i),
                      children: const [
                        _BasicPad(),
                        _SplitTab(),
                        _DiscountTab(),
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

  void _showHistory(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showAppSheet<void>(
      context,
      title: l10n.calcHistory,
      glyph: FinGlyph.history,
      builder: (context, _) => Consumer(
        builder: (context, ref, _) {
          final history = ref.watch(calcHistoryProvider);
          if (history.isEmpty) {
            return EmptyState(
              glyph: FinGlyph.calculator,
              title: l10n.calcHistoryEmpty,
              compact: true,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < history.length; i++)
                Entrance(
                  index: i,
                  offset: 8,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaces.surface2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate_rounded,
                            size: 18, color: Color(0xFF0EA5E9),),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            history[i],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              AppButton(
                label: l10n.clearHistory,
                icon: Icons.delete_sweep_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    ref.read(calcHistoryProvider.notifier).state = [],
              ),
            ],
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
    return HeroPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CountUp(
                        value: amount,
                        format: Formatters.moneyWhole,
                        duration: AppMotion.medium,
                        style: AppTypography.money(
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SpinningCoin(size: 52),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: l10n.addAsTransaction,
            icon: Icons.add_rounded,
            variant: AppButtonVariant.gold,
            onPressed: amount <= 0
                ? null
                : () => context.push(
                      '/dashboard/transaction',
                      extra: NewTxnArgs(amount: amount),
                    ),
          ),
        ],
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

  void _step(int by) {
    final n = (int.tryParse(_members.text.trim()) ?? 0) + by;
    if (n < 1) return;
    AppHaptics.select();
    setState(() => _members.text = '$n');
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
    final n = int.tryParse(_members.text.trim()) ?? 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Entrance(
          child: Text(
            'Turf, trip, hostel, dinner — split evenly in seconds.',
            style: TextStyle(color: context.semantic.muted),
          ),
        ),
        const SizedBox(height: 18),
        Entrance(
          index: 1,
          child: AppTextField(
            controller: _total,
            label: l10n.totalAmount,
            prefixText: '₹ ',
            icon: Icons.receipt_long_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        Entrance(
          index: 2,
          child: Surface3D(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon3D(
                  icon: Icons.groups_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.numMembers,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconOrb(icon: Icons.remove_rounded, size: 38, onTap: () => _step(-1)),
                SizedBox(
                  width: 44,
                  child: PopOnChange(
                    trigger: n,
                    child: Text(
                      '$n',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                IconOrb(icon: Icons.add_rounded, size: 38, onTap: () => _step(1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (n > 0)
          Entrance(
            index: 3,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < n.clamp(0, 12); i++)
                  PopOnChange(
                    trigger: n,
                    child: const Icon(Icons.person_rounded,
                        color: Color(0xFF0EA5E9), size: 22,),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Entrance(
          index: 4,
          child: _ResultBar(label: l10n.perPerson, amount: _perPerson),
        ),
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
        Entrance(
          child: AppTextField(
            controller: _amount,
            label: l10n.totalAmount,
            prefixText: '₹ ',
            icon: Icons.sell_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        Entrance(
          index: 1,
          child: AppTextField(
            controller: _pct,
            label: l10n.discountPercent,
            icon: Icons.percent_rounded,
            suffix: const Padding(
              padding: EdgeInsets.only(right: 14, top: 14),
              child: Text('%', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        Entrance(
          index: 2,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in const ['5', '10', '15', '20', '25', '50'])
                TagChip(
                  label: '$p%',
                  selected: _pct.text.trim() == p,
                  color: AppColors.income,
                  onTap: () => setState(() => _pct.text = p),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Container(
            key: ValueKey(_saved.round()),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.semantic.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_rounded,
                    size: 18, color: context.semantic.income,),
                const SizedBox(width: 8),
                Text(
                  'You save ${Formatters.moneyWhole(_saved)}',
                  style: TextStyle(
                    color: context.semantic.income,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _ResultBar(
          label: l10n.result,
          amount: _finalAmount < 0 ? 0 : _finalAmount,
        ),
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
                (h) => ['$expr = ${_trim(value)}', ...h].take(50).toList(),
              );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Expression + result display.
          HeroPanel(
            radius: 26,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _tokens.isEmpty && _result == null ? ' ' : _expression,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(a),
                          child: c,
                        ),
                      ),
                      child: Text(
                        _result != null ? '= $_display' : _display,
                        key: ValueKey('$_result$_display'),
                        maxLines: 1,
                        style: AppTypography.money(
                          size: 44,
                          color: _result != null
                              ? AppColors.accentSoft
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
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
                            wide: row.length == 3 && (k == 'C' || k == '0'),
                            kind: k == '='
                                ? _KeyKind.equals
                                : (['÷', '×', '−', '+'].contains(k)
                                    ? _KeyKind.op
                                    : (k == 'C' || k == '⌫'
                                        ? _KeyKind.fn
                                        : _KeyKind.digit)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: l10n.addAsTransaction,
            icon: Icons.add_rounded,
            variant: AppButtonVariant.gold,
            onPressed: amount <= 0
                ? null
                : () => context.push(
                      '/dashboard/transaction',
                      extra: NewTxnArgs(amount: amount),
                    ),
          ),
        ],
      ),
    );
  }
}

enum _KeyKind { digit, op, fn, equals }

/// A pushable 3D calculator key.
class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.kind,
    this.wide = false,
  });

  final String label;
  final VoidCallback onTap;
  final _KeyKind kind;
  final bool wide;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    const sky = Color(0xFF0EA5E9);
    final (Color face, Color side, Color fg) = switch (widget.kind) {
      _KeyKind.digit => (s.card, context.semantic.border, Theme.of(context).colorScheme.onSurface),
      _KeyKind.op => (sky.withValues(alpha: s.isDark ? 0.25 : 0.14), sky.withValues(alpha: 0.35), sky),
      _KeyKind.fn => (s.surface2, context.semantic.border, context.semantic.expense),
      _KeyKind.equals => (AppColors.primary, AppColors.primaryDark, Colors.white),
    };
    const depth = 4.0;
    return Expanded(
      flex: widget.wide ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: () {
            AppHaptics.select();
            widget.onTap();
          },
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: c.maxHeight - depth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: side,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: _down ? AppMotion.tap : AppMotion.medium,
                  curve: _down ? Curves.easeOut : AppMotion.bouncy,
                  left: 0,
                  right: 0,
                  top: _down ? depth : 0,
                  height: c.maxHeight - depth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: face,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: widget.kind == _KeyKind.digit
                            ? context.semantic.border.withValues(alpha: 0.6)
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
