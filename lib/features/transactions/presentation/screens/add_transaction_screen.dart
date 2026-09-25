import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/date_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_editor.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../new_txn_args.dart';
import '../providers/transaction_providers.dart';
import '../txn_ui.dart';
import 'transaction_detail_screen.dart';

/// Add or edit a transaction, presented as a full-height bottom sheet. Pass
/// [existing] to edit, or [args] to start a new entry with a preset
/// type/amount/category (from a quick action, category, or the calculator).
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.existing, this.args});
  final TxnEntry? existing;
  final NewTxnArgs? args;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
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
  int _amountShake = 0;

  // Drag-to-dismiss for the sheet header.
  double _drag = 0;
  late final AnimationController _settle;
  double _dragFrom = 0;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy controller would first be built in dispose().
    _settle = AnimationController(vsync: this, duration: AppMotion.medium)
      ..addListener(() {
        setState(() => _drag = _dragFrom * (1 - _settle.value));
      });
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
      _amount.text = _plain(presetAmount);
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
    _settle.dispose();
    super.dispose();
  }

  static String _plain(double v) =>
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  void _bump(double by) {
    final current = double.tryParse(_amount.text.trim()) ?? 0;
    final next = math.min(current + by, Validators.maxAmount);
    AppHaptics.select();
    setState(() => _amount.text = _plain(next));
  }

  Future<void> _pickDate({required bool due}) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppDatePicker(
      context,
      initial: due ? (_dueDate ?? DateTime.now()) : _date,
      first: DateTime(2015),
      last: DateTime(2100),
      title: due ? l10n.returnCommitmentDate : _type.dateLabel(l10n),
      accent: _accent(context),
    );
    if (picked != null) {
      setState(() => due ? _dueDate = picked : _date = picked);
    }
  }

  Future<void> _pickRecurrenceStart() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppDatePicker(
      context,
      initial: _recurrenceStart ?? _date,
      first: DateTime(2015),
      last: DateTime(2100),
      title: l10n.repeatStartsOn,
      accent: _accent(context),
    );
    if (picked != null) setState(() => _recurrenceStart = picked);
  }

  Color _accent(BuildContext context) =>
      context.semantic.byTypeKey(_type.key);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    if (!_formKey.currentState!.validate()) {
      setState(() => _amountShake++);
      return;
    }
    final categoryId = _categoryId ?? ref.read(defaultCategoryIdProvider);
    if (categoryId == null) {
      toast.error(l10n.category);
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
        interestPercent:
            _type.isLoan ? double.tryParse(_interest.text.trim()) : null,
        dueDate: _type.isLoan ? _dueDate : null,
        recurrence: _recurrence,
        recurrenceStart:
            _recurrence.isRecurring ? (_recurrenceStart ?? _date) : null,
      );
      await ref.read(transactionActionsProvider).save(entry);
      if (!mounted) return;
      showSuccessBurst(context, message: l10n.savedToast);
      context.pop();
    } catch (_) {
      toast.error(l10n.somethingWrong, retryLabel: l10n.retry, onRetry: _save);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final cat = ref.read(categoryByIdProvider)[widget.existing!.categoryId];
    setState(() => _saving = true);
    final deleted = await confirmDeleteTransaction(
      context,
      ref,
      widget.existing!,
      cat?.name,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (deleted) context.pop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _settle.stop();
    setState(() => _drag = math.max(0, _drag + d.delta.dy));
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_drag > 140 || v > 900) {
      context.pop();
      return;
    }
    _dragFrom = _drag;
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];
    final effectiveCatId = _categoryId ?? ref.watch(defaultCategoryIdProvider);
    final selectedCat =
        categories.where((c) => c.id == effectiveCatId).firstOrNull;
    final accent = _accent(context);
    final s = context.surfaces;

    return AnimatedTheme(
      duration: AppMotion.medium,
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // Tap the dimmed area above the sheet to close.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.pop(),
              child: SizedBox(height: media.padding.top + 18, width: double.infinity),
            ),
            Expanded(
              child: Transform.translate(
                offset: Offset(0, _drag),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Container(
                      decoration: BoxDecoration(
                        color: s.sheet,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 40,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Accent wash that follows the selected type.
                          Positioned(
                            top: -120,
                            left: -60,
                            right: -60,
                            child: AnimatedContainer(
                              duration: AppMotion.slow,
                              height: 260,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    accent.withValues(alpha: s.isDark ? 0.28 : 0.16),
                                    accent.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragUpdate: _onDragUpdate,
                                onVerticalDragEnd: _onDragEnd,
                                child: _header(context, l10n, accent),
                              ),
                              Expanded(
                                child: Form(
                                  key: _formKey,
                                  child: ListView(
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 4, 20, 16),
                                    children: _fields(
                                      context,
                                      l10n,
                                      categories,
                                      selectedCat,
                                      accent,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  math.max(media.padding.bottom, 12) + 4,
                                ),
                                child: AppButton(
                                  label: _isEdit ? l10n.update : l10n.save,
                                  loading: _saving,
                                  icon: Icons.check_rounded,
                                  color: accent,
                                  onPressed: _save,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n, Color accent) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: context.semantic.muted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 14, 12),
          child: Row(
            children: [
              PopOnChange(
                trigger: _type,
                child: Icon3D(glyph: _type.glyph, size: 44),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? l10n.editTransaction : l10n.addTransaction,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Text(
                        _type.label(l10n),
                        key: ValueKey(_type),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEdit) ...[
                IconOrb(
                  icon: Icons.delete_rounded,
                  size: 40,
                  color: context.semantic.expense,
                  tooltip: l10n.delete,
                  onTap: _saving ? null : _delete,
                ),
                const SizedBox(width: 8),
              ],
              IconOrb(
                icon: Icons.close_rounded,
                size: 40,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onTap: () => context.pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _fields(
    BuildContext context,
    AppLocalizations l10n,
    List<Category> categories,
    Category? selectedCat,
    Color accent,
  ) {
    return [
      Entrance(
        child: _TypeSelector(
          type: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
      ),
      const SizedBox(height: 18),

      // ---- Hero amount ----
      Entrance(
        index: 1,
        child: Shake(
          trigger: _amountShake,
          child: _AmountInput(
            controller: _amount,
            color: accent,
            onChanged: () => setState(() {}),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Entrance(
        index: 2,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in const [100.0, 500.0, 1000.0, 5000.0])
              _QuickAmount(
                label: '+${Formatters.moneyWhole(v)}',
                color: accent,
                onTap: () => _bump(v),
              ),
          ],
        ),
      ),
      const SizedBox(height: 22),

      // ---- Category ----
      Entrance(
        index: 3,
        child: AppPickerField(
          label: l10n.category,
          value: selectedCat?.name,
          accent: accent,
          leading: selectedCat == null
              ? const Icon3D(
                  glyph: FinGlyph.categories,
                  size: 38,
                  style: Icon3DStyle.soft,
                )
              : PopOnChange(
                  trigger: selectedCat.id,
                  child: Icon3D(
                    icon: iconFromCode(selectedCat.iconCode),
                    color: AppColors.chartFor(selectedCat.colorIndex),
                    size: 38,
                  ),
                ),
          onTap: () => _pickCategory(categories),
        ),
      ),
      AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        child: selectedCat != null && selectedCat.subCategories.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GroupLabel(l10n.subcategory,
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sub in selectedCat.subCategories)
                          TagChip(
                            label: sub.name,
                            color: AppColors.chartFor(selectedCat.colorIndex),
                            selected: _subCategoryId == sub.id,
                            onTap: () => setState(
                              () => _subCategoryId =
                                  _subCategoryId == sub.id ? null : sub.id,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      const SizedBox(height: 14),

      // ---- Date ----
      Entrance(
        index: 4,
        child: AppPickerField(
          label: _type.dateLabel(l10n),
          value: Formatters.fullDate(_date),
          icon: Icons.calendar_month_rounded,
          accent: accent,
          leading: const Icon3D(
            glyph: FinGlyph.calendar,
            size: 38,
            style: Icon3DStyle.soft,
          ),
          onTap: () => _pickDate(due: false),
        ),
      ),

      // ---- Loan-only fields ----
      AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        alignment: Alignment.topCenter,
        child: !_type.isLoan
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Entrance(
                  key: ValueKey(_type),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _person,
                          label: l10n.personName,
                          hint: l10n.optionalPerson,
                          icon: Icons.person_rounded,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _interest,
                                label: l10n.interest,
                                hint: '0',
                                icon: Icons.percent_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppPickerField(
                                label: l10n.returnCommitmentDate,
                                value: _dueDate == null
                                    ? null
                                    : Formatters.fullDate(_dueDate!),
                                icon: Icons.event_available_rounded,
                                accent: accent,
                                onTap: () => _pickDate(due: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      const SizedBox(height: 20),

      // ---- Recurrence ----
      Entrance(
        index: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupLabel(l10n.repeatEvery,
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final r in Recurrence.values) ...[
                    TagChip(
                      label: r.label(l10n),
                      icon: r.isRecurring ? Icons.repeat_rounded : null,
                      color: accent,
                      selected: _recurrence == r,
                      onTap: () => setState(() => _recurrence = r),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        child: _recurrence.isRecurring
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AppPickerField(
                  label: l10n.repeatStartsOn,
                  value: Formatters.fullDate(_recurrenceStart ?? _date),
                  icon: Icons.event_repeat_rounded,
                  accent: accent,
                  onTap: _pickRecurrenceStart,
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      const SizedBox(height: 20),

      // ---- Note ----
      Entrance(
        index: 6,
        child: AppTextField(
          controller: _note,
          label: '${l10n.note} (${l10n.optional})',
          icon: Icons.sticky_note_2_rounded,
          maxLength: 140,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
    ];
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final chosen = await showCategoryPickerSheet(
      context,
      categories: categories,
      selectedId: _categoryId ?? ref.read(defaultCategoryIdProvider),
    );
    if (chosen == null || !mounted) return;
    if (chosen.createNew) {
      final created = await showCategoryEditor(context);
      if (created != null) {
        await ref.read(categoryActionsProvider).save(created);
        if (!mounted) return;
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

/// Four type cards with a sliding, colour-changing highlight.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.type, required this.onChanged});
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final s = context.surfaces;
    final index = TransactionType.values.indexOf(type);
    final color = semantic.byTypeKey(type.key);

    return Container(
      height: 104,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: s.surface2,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / 4;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.medium,
                curve: AppMotion.spring,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [s.cardHi, s.card],
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: AppSurfaces.glow(color, strength: 0.5),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in TransactionType.values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (t == type) return;
                          AppHaptics.select();
                          onChanged(t);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: t == type ? 1 : 0.82,
                              duration: AppMotion.medium,
                              curve: AppMotion.bouncy,
                              child: AnimatedOpacity(
                                opacity: t == type ? 1 : 0.55,
                                duration: AppMotion.fast,
                                child: Icon3D(
                                  glyph: t.glyph,
                                  size: 38,
                                  coin: false,
                                  style: t == type
                                      ? Icon3DStyle.solid
                                      : Icon3DStyle.soft,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                t.label(l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight:
                                      t == type ? FontWeight.w800 : FontWeight.w600,
                                  color: t == type
                                      ? semantic.byTypeKey(t.key)
                                      : semantic.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The big ₹ amount input. Validation messages appear under it; the whole
/// block shakes when saving with an invalid amount.
class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.color,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = context.surfaces;
    final value = double.tryParse(controller.text.trim()) ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [s.cardHi, s.card],
        ),
        boxShadow: s.elevation(0.8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            l10n.amount,
            style: TextStyle(
              color: context.semantic.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Coin3D(size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (v) => Validators.amount(v),
                  onChanged: (_) => onChanged(),
                  style: AppTypography.money(size: 40, color: color),
                  cursorColor: color,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTypography.money(
                      size: 40,
                      color: context.semantic.muted.withValues(alpha: 0.4),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    errorStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 50),
            ],
          ),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Text(
              value > 0 ? Formatters.money(value) : ' ',
              key: ValueKey(value),
              style: TextStyle(
                color: context.semantic.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmount extends StatelessWidget {
  const _QuickAmount({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.9,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Result of the category sheet: either a chosen category or "create new".
class CatPick {
  const CatPick.category(this.category) : createNew = false;
  const CatPick.create()
      : category = null,
        createNew = true;
  final Category? category;
  final bool createNew;
}

/// Grid of 3D category tiles plus a "create new" tile.
Future<CatPick?> showCategoryPickerSheet(
  BuildContext context, {
  required List<Category> categories,
  String? selectedId,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppSheet<CatPick>(
    context,
    title: l10n.category,
    glyph: FinGlyph.categories,
    builder: (context, _) => LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 460 ? 4 : 3;
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: w,
              child: Entrance(
                child: _CategoryTile(
                  name: l10n.createNewCategory.replaceAll('＋', '').trim(),
                  icon: Icons.add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  dashed: true,
                  onTap: () => Navigator.pop(context, const CatPick.create()),
                ),
              ),
            ),
            for (var i = 0; i < categories.length; i++)
              SizedBox(
                width: w,
                child: Entrance(
                  index: i + 1,
                  child: _CategoryTile(
                    name: categories[i].name,
                    icon: iconFromCode(categories[i].iconCode),
                    color: AppColors.chartFor(categories[i].colorIndex),
                    count: categories[i].subCategories.length,
                    selected: categories[i].id == selectedId,
                    onTap: () => Navigator.pop(
                      context,
                      CatPick.category(categories[i]),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
    this.count = 0,
    this.selected = false,
    this.dashed = false,
  });

  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int count;
  final bool selected;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.93,
      child: Container(
        height: 118,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? color.withValues(alpha: s.isDark ? 0.2 : 0.1)
              : (dashed ? Colors.transparent : s.card),
          border: Border.all(
            color: selected
                ? color
                : (dashed
                    ? color.withValues(alpha: 0.5)
                    : context.semantic.border),
            width: selected || dashed ? 1.6 : 1,
          ),
          boxShadow: selected || dashed ? null : s.elevation(0.4),
        ),
        child: Column(
          children: [
            Icon3D(
              icon: icon,
              color: color,
              size: 46,
              style: dashed ? Icon3DStyle.soft : Icon3DStyle.solid,
            ),
            const Spacer(),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: dashed ? color : null,
              ),
            ),
            if (count > 0)
              Text(
                '$count',
                style: TextStyle(
                  color: context.semantic.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
