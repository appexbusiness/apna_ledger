import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/transaction.dart';
import '../ledger_export.dart';
import '../providers/transaction_providers.dart';

/// Search box + type filter chips + active-filter banner + CSV export.
/// Reads/writes the shared [txnFilterProvider] so it works the same on the
/// home ledger-history preview and the full Transactions tab.
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
    _search =
        TextEditingController(text: ref.read(txnFilterProvider).query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleType(TransactionType t) {
    final f = ref.read(txnFilterProvider);
    final types = Set<TransactionType>.from(f.types);
    types.contains(t) ? types.remove(t) : types.add(t);
    ref.read(txnFilterProvider.notifier).state = f.copyWith(types: types);
  }

  void _clear() {
    _search.clear();
    ref.read(txnFilterProvider.notifier).state = const TxnFilter();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(txnFilterProvider);
    final semantic = context.semantic;

    String typeLabel(TransactionType t) {
      switch (t) {
        case TransactionType.income:
          return l10n.income;
        case TransactionType.expense:
          return l10n.expense;
        case TransactionType.loanGiven:
          return l10n.loanGiven;
        case TransactionType.loanTaken:
          return l10n.loanTaken;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _search,
                hint: l10n.searchHint,
                prefix: Icon(Icons.search, color: semantic.muted),
                onChanged: (v) {
                  ref.read(txnFilterProvider.notifier).state =
                      ref.read(txnFilterProvider).copyWith(query: v);
                },
              ),
            ),
            IconButton(
              tooltip: l10n.download,
              onPressed: _busy ? null : _export,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.download_outlined),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in TransactionType.values) ...[
                FilterChip(
                  label: Text(typeLabel(t)),
                  selected: filter.types.contains(t),
                  onSelected: (_) => _toggleType(t),
                  selectedColor: semantic.byTypeKey(t.key).withValues(alpha: 0.18),
                  checkmarkColor: semantic.byTypeKey(t.key),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (filter.isActive) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.filter_alt, size: 16, color: semantic.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.filter,
                    style: TextStyle(color: semantic.muted, fontSize: 13)),
              ),
              TextButton(
                onPressed: _clear,
                child: Text(l10n.clear),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
