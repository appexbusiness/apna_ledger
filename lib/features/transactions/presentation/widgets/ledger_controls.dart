import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/date_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../ledger_export.dart';
import '../providers/transaction_providers.dart';
import '../txn_ui.dart';

/// Search + quick type chips + filter sheet + active-filter chips + export.
/// Reads/writes the shared [txnFilterProvider] so it works the same on the
/// home ledger preview and the full Transactions tab.
class LedgerControls extends ConsumerStatefulWidget {
  const LedgerControls({super.key});

  @override
  ConsumerState<LedgerControls> createState() => _LedgerControlsState();
}

class _LedgerControlsState extends ConsumerState<LedgerControls> {
  late final TextEditingController _search;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(txnFilterProvider).query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _set(TxnFilter f) => ref.read(txnFilterProvider.notifier).state = f;

  void _toggleType(TransactionType t) {
    final f = ref.read(txnFilterProvider);
    final types = Set<TransactionType>.from(f.types);
    types.contains(t) ? types.remove(t) : types.add(t);
    _set(f.copyWith(types: types));
  }

  void _clear() {
    _search.clear();
    _set(const TxnFilter());
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await runLedgerDownload(
        context,
        ref,
        source: ref.read(filteredTransactionsProvider),
        fileBase: 'apna-ledger-history',
        title: AppLocalizations.of(context).ledgerHistory,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await showLedgerFilterSheet(
      context,
      ref.read(txnFilterProvider),
    );
    if (result != null) _set(result.copyWith(query: _search.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(txnFilterProvider);
    final cats = ref.watch(categoryByIdProvider);
    final semantic = context.semantic;

    // Keep the box in sync when another screen resets the filter.
    ref.listen(txnFilterProvider.select((f) => f.query), (_, next) {
      if (_search.text != next) _search.text = next;
    });

    final extraFilters = <Widget>[
      if (filter.categoryId != null)
        _ActiveChip(
          label: [
            cats[filter.categoryId]?.name ?? l10n.category,
            if (filter.subCategoryId != null)
              cats[filter.categoryId]
                      ?.subCategories
                      .where((s) => s.id == filter.subCategoryId)
                      .map((s) => s.name)
                      .firstOrNull ??
                  '',
          ].where((e) => e.isNotEmpty).join(' › '),
          icon: Icons.widgets_rounded,
          onRemove: () => _set(filter.copyWith(clearCategory: true)),
        ),
      if (filter.from != null || filter.to != null)
        _ActiveChip(
          label:
              '${filter.from == null ? l10n.anyDate : Formatters.dayMonth(filter.from!)} → ${filter.to == null ? l10n.anyDate : Formatters.dayMonth(filter.to!)}',
          icon: Icons.date_range_rounded,
          onRemove: () => _set(filter.copyWith(clearDates: true)),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _search,
                hint: l10n.searchHint,
                icon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                suffix: filter.query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: semantic.muted),
                        onPressed: () {
                          _search.clear();
                          _set(filter.copyWith(query: ''));
                        },
                      ),
                onChanged: (v) =>
                    _set(ref.read(txnFilterProvider).copyWith(query: v)),
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconOrb(
                  icon: Icons.tune_rounded,
                  tooltip: l10n.filter,
                  size: 50,
                  onTap: _openFilters,
                ),
                if (filter.categoryId != null ||
                    filter.from != null ||
                    filter.to != null)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.surfaces.card,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            IconOrb(
              icon: Icons.download_rounded,
              tooltip: l10n.download,
              size: 50,
              busy: _busy,
              onTap: _export,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final t in TransactionType.values) ...[
                TagChip(
                  label: t.label(l10n),
                  selected: filter.types.contains(t),
                  color: semantic.byTypeKey(t.key),
                  onTap: () => _toggleType(t),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          child: filter.isActive
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...extraFilters,
                      Pressable(
                        onTap: _clear,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_rounded,
                                  size: 16, color: semantic.expense,),
                              const SizedBox(width: 4),
                              Text(
                                l10n.clear,
                                style: TextStyle(
                                  color: semantic.expense,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Entrance(
      offset: 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.close_rounded, size: 16, color: c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter sheet over the existing [TxnFilter] fields: types, category and
/// date range. Returns the new filter (query untouched) or null.
Future<TxnFilter?> showLedgerFilterSheet(
  BuildContext context,
  TxnFilter current,
) {
  final l10n = AppLocalizations.of(context);
  return showAppSheet<TxnFilter>(
    context,
    title: l10n.filter,
    glyph: FinGlyph.filter,
    builder: (context, _) => _FilterBody(initial: current, l10n: l10n),
  );
}

class _FilterBody extends ConsumerStatefulWidget {
  const _FilterBody({required this.initial, required this.l10n});
  final TxnFilter initial;
  final AppLocalizations l10n;

  @override
  ConsumerState<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends ConsumerState<_FilterBody> {
  late final Set<TransactionType> _types = {...widget.initial.types};
  late String? _cat = widget.initial.categoryId;
  late String? _sub = widget.initial.subCategoryId;
  late DateTime? _from = widget.initial.from;
  late DateTime? _to = widget.initial.to;

  Future<void> _pick(bool from) async {
    final picked = await showAppDatePicker(
      context,
      initial: (from ? _from : _to) ?? DateTime.now(),
      first: DateTime(2015),
      last: DateTime(2100),
      title: from ? widget.l10n.dateFrom : widget.l10n.dateTo,
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        // Inclusive: cover the whole "to" day.
        _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final semantic = context.semantic;
    final cats = ref.watch(categoriesStreamProvider).value ?? const [];
    final selectedCat = cats.where((c) => c.id == _cat).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupLabel(l10n.types, padding: const EdgeInsets.fromLTRB(4, 0, 4, 10)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in TransactionType.values)
              TagChip(
                label: t.label(l10n),
                color: semantic.byTypeKey(t.key),
                selected: _types.contains(t),
                onTap: () => setState(
                  () => _types.contains(t) ? _types.remove(t) : _types.add(t),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        GroupLabel(l10n.category,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              TagChip(
                label: l10n.all,
                selected: _cat == null,
                onTap: () => setState(() {
                  _cat = null;
                  _sub = null;
                }),
              ),
              for (final c in cats) ...[
                const SizedBox(width: 8),
                TagChip(
                  label: c.name,
                  icon: iconFromCode(c.iconCode),
                  color: AppColors.chartFor(c.colorIndex),
                  selected: _cat == c.id,
                  onTap: () => setState(() {
                    _cat = c.id;
                    _sub = null;
                  }),
                ),
              ],
            ],
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          child: selectedCat == null || selectedCat.subCategories.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in selectedCat.subCategories)
                        TagChip(
                          label: s.name,
                          color: AppColors.chartFor(selectedCat.colorIndex),
                          selected: _sub == s.id,
                          onTap: () => setState(
                            () => _sub = _sub == s.id ? null : s.id,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 20),
        GroupLabel(l10n.dateRange,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),),
        Row(
          children: [
            Expanded(
              child: AppPickerField(
                label: l10n.dateFrom,
                value: _from == null ? null : Formatters.fullDate(_from!),
                placeholder: l10n.anyDate,
                icon: Icons.event_rounded,
                onTap: () => _pick(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppPickerField(
                label: l10n.dateTo,
                value: _to == null ? null : Formatters.fullDate(_to!),
                placeholder: l10n.anyDate,
                icon: Icons.event_rounded,
                onTap: () => _pick(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: l10n.clear,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(
                  context,
                  TxnFilter(query: widget.initial.query),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: l10n.apply,
                icon: Icons.check_rounded,
                onPressed: () => Navigator.pop(
                  context,
                  TxnFilter(
                    query: widget.initial.query,
                    types: _types,
                    categoryId: _cat,
                    subCategoryId: _sub,
                    from: _from,
                    to: _to,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
