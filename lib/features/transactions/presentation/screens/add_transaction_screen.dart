import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_editor.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../new_txn_args.dart';
import '../providers/transaction_providers.dart';

/// Add or edit a transaction. Pass [existing] to edit, or [args] to start a new
/// entry with a preset type/amount (from a home quick-card or the calculator).
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.existing, this.args});
  final TxnEntry? existing;
  final NewTxnArgs? args;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _person = TextEditingController();
  final _interest = TextEditingController();

  late TransactionType _type;
  String? _categoryId;
  String? _subCategoryId;
  late DateTime _date;
  DateTime? _dueDate;
  Recurrence _recurrence = Recurrence.once;
  DateTime? _recurrenceStart;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.args?.type ?? TransactionType.expense;
    _categoryId = e?.categoryId ?? widget.args?.categoryId;
    _subCategoryId = e?.subCategoryId ?? widget.args?.subCategoryId;
    _date = e?.date ?? DateTime.now();
    _dueDate = e?.dueDate;
    _recurrence = e?.recurrence ?? Recurrence.once;
    _recurrenceStart = e?.recurrenceStart;
    final presetAmount = e?.amount ?? widget.args?.amount;
    if (presetAmount != null && presetAmount > 0) {
      _amount.text = presetAmount.toStringAsFixed(
          presetAmount == presetAmount.roundToDouble() ? 0 : 2);
    }
    if (e != null) {
      _note.text = e.note;
      _person.text = e.counterparty ?? '';
      _interest.text = e.interestPercent?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _person.dispose();
    _interest.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final initial = due ? (_dueDate ?? DateTime.now()) : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => due ? _dueDate = picked : _date = picked);
    }
  }

  Future<void> _pickRecurrenceStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceStart ?? _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _recurrenceStart = picked);
  }

  String _dateLabel(AppLocalizations l10n) {
    switch (_type) {
      case TransactionType.income:
        return l10n.incomeDate;
      case TransactionType.expense:
        return l10n.spendingDate;
      case TransactionType.loanGiven:
        return l10n.moneyGivenDate;
      case TransactionType.loanTaken:
        return l10n.moneyTakenDate;
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _categoryId ?? ref.read(defaultCategoryIdProvider);
    if (categoryId == null) {
      _snack(l10n.category);
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      final entry = TxnEntry(
        id: widget.existing?.id ?? const Uuid().v4(),
        userId: userId,
        type: _type,
        amount: double.parse(_amount.text.trim()),
        categoryId: categoryId,
        subCategoryId: _subCategoryId,
        date: _date,
        note: _note.text.trim(),
        counterparty:
            _person.text.trim().isEmpty ? null : _person.text.trim(),
        interestPercent: _type.isLoan
            ? double.tryParse(_interest.text.trim())
            : null,
        dueDate: _type.isLoan ? _dueDate : null,
        recurrence: _recurrence,
        recurrenceStart:
            _recurrence.isRecurring ? (_recurrenceStart ?? _date) : null,
      );
      await ref.read(transactionActionsProvider).save(entry);
      if (mounted) context.pop();
    } catch (_) {
      _snack(l10n.somethingWrong);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await ref.read(transactionActionsProvider).delete(widget.existing!.id);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];
    final effectiveCatId = _categoryId ?? ref.watch(defaultCategoryIdProvider);
    final selectedCat =
        categories.where((c) => c.id == effectiveCatId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editTransaction : l10n.addTransaction),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _TypeSelector(
                    type: _type,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: 22),
                  AppTextField(
                    controller: _amount,
                    label: l10n.amount,
                    hint: '0',
                    prefixText: '₹ ',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) => Validators.amount(v),
                  ),
                  const SizedBox(height: 16),
                  _PickerField(
                    label: l10n.category,
                    value: selectedCat?.name,
                    onTap: () => _pickCategory(categories),
                  ),
                  if (selectedCat != null &&
                      selectedCat.subCategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SubCategoryPicker(
                      label: l10n.subcategory,
                      category: selectedCat,
                      selectedId: _subCategoryId,
                      onSelected: (id) => setState(() => _subCategoryId = id),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PickerField(
                    label: _dateLabel(l10n),
                    value: Formatters.fullDate(_date),
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDate(due: false),
                  ),

                  // ---- Loan-only fields ----
                  if (_type.isLoan) ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _person,
                      label: l10n.personName,
                      hint: l10n.optionalPerson,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _interest,
                            label: l10n.interest,
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PickerField(
                            label: l10n.returnCommitmentDate,
                            value: _dueDate == null
                                ? '—'
                                : Formatters.fullDate(_dueDate!),
                            icon: Icons.event_outlined,
                            onTap: () => _pickDate(due: true),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  _RecurrencePicker(
                    value: _recurrence,
                    onChanged: (r) => setState(() => _recurrence = r),
                  ),
                  if (_recurrence.isRecurring) ...[
                    const SizedBox(height: 16),
                    _PickerField(
                      label: l10n.repeatStartsOn,
                      value: Formatters.fullDate(_recurrenceStart ?? _date),
                      icon: Icons.event_repeat_outlined,
                      onTap: _pickRecurrenceStart,
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _note,
                    label: l10n.note,
                    hint: '${l10n.note} (${l10n.optional})',
                    maxLength: 140,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isEdit ? l10n.update : l10n.save,
                    loading: _saving,
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<_CatPick>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CategorySheet(
        categories: categories,
        title: l10n.category,
        createLabel: l10n.createNewCategory,
      ),
    );
    if (chosen == null) return;
    if (chosen.createNew) {
      final created = await showCategoryEditor(context);
      if (created != null) {
        await ref.read(categoryActionsProvider).save(created);
        setState(() {
          _categoryId = created.id;
          _subCategoryId = null;
        });
      }
      return;
    }
    setState(() {
      _categoryId = chosen.category!.id;
      _subCategoryId = null;
    });
  }
}

/// 2×2 grid of the four transaction types, each in its own colour.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.type, required this.onChanged});
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;

    Widget cell(TransactionType t, String label, IconData icon) {
      final color = semantic.byTypeKey(t.key);
      final selected = type == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.14) : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : semantic.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? color : semantic.muted),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? color : semantic.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            cell(TransactionType.income, l10n.income,
                Icons.south_west_rounded),
            cell(TransactionType.expense, l10n.expense,
                Icons.north_east_rounded),
          ],
        ),
        Row(
          children: [
            cell(TransactionType.loanGiven, l10n.loanGiven,
                Icons.call_made_rounded),
            cell(TransactionType.loanTaken, l10n.loanTaken,
                Icons.call_received_rounded),
          ],
        ),
      ],
    );
  }
}

class _RecurrencePicker extends StatelessWidget {
  const _RecurrencePicker({required this.value, required this.onChanged});
  final Recurrence value;
  final ValueChanged<Recurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(Recurrence r) {
      switch (r) {
        case Recurrence.once:
          return l10n.oneTime;
        case Recurrence.daily:
          return l10n.daily;
        case Recurrence.weekly:
          return l10n.weekly;
        case Recurrence.monthly:
          return l10n.monthly;
        case Recurrence.yearly:
          return l10n.yearly;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.repeatEvery,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in Recurrence.values)
              ChoiceChip(
                label: Text(label(r)),
                selected: value == r,
                onSelected: (_) => onChanged(r),
              ),
          ],
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.expand_more_rounded,
  });
  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value == null ? context.semantic.muted : null,
                    ),
                  ),
                ),
                Icon(icon, color: context.semantic.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SubCategoryPicker extends StatelessWidget {
  const _SubCategoryPicker({
    required this.label,
    required this.category,
    required this.selectedId,
    required this.onSelected,
  });
  final String label;
  final Category category;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in category.subCategories)
              ChoiceChip(
                label: Text(s.name),
                selected: selectedId == s.id,
                onSelected: (v) => onSelected(v ? s.id : null),
              ),
          ],
        ),
      ],
    );
  }
}

/// Result of the category sheet: either a chosen category or "create new".
class _CatPick {
  const _CatPick.category(this.category) : createNew = false;
  const _CatPick.create()
      : category = null,
        createNew = true;
  final Category? category;
  final bool createNew;
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
    required this.categories,
    required this.title,
    required this.createLabel,
  });
  final List<Category> categories;
  final String title;
  final String createLabel;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    child: Icon(Icons.add,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(createLabel,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                  onTap: () =>
                      Navigator.of(context).pop(const _CatPick.create()),
                ),
                const Divider(height: 1),
                for (final c in categories)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.10),
                      child: Icon(
                        iconFromCode(c.iconCode),
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: c.subCategories.isEmpty
                        ? null
                        : Text('${c.subCategories.length} sub-categories'),
                    onTap: () =>
                        Navigator.of(context).pop(_CatPick.category(c)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
