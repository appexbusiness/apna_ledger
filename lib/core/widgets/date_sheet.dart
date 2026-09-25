import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/fin_icons.dart';
import '../design/motion.dart';
import '../design/surfaces.dart';
import '../utils/formatters.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';

/// Date selection as a bottom sheet: quick picks (Today / Yesterday), a
/// calendar, and a confirm button that echoes the chosen date.
/// Returns the picked day (at midnight, like [showDatePicker]) or null.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  String? title,
  Color? accent,
}) {
  final l10n = AppLocalizations.of(context);
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  bool inRange(DateTime d) => !d.isBefore(day(first)) && !d.isAfter(last);

  var selected = day(initial);
  if (selected.isBefore(day(first))) selected = day(first);
  if (selected.isAfter(last)) selected = day(last);
  final today = day(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));
  final color = accent ?? Theme.of(context).colorScheme.primary;

  return showAppSheet<DateTime>(
    context,
    title: title ?? l10n.selectDate,
    glyph: FinGlyph.calendar,
    accent: accent,
    builder: (context, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (inRange(today))
              TagChip(
                label: l10n.today,
                icon: Icons.today_rounded,
                color: color,
                selected: selected == today,
                onTap: () => setSheet(() => selected = today),
              ),
            if (inRange(yesterday))
              TagChip(
                label: l10n.yesterday,
                icon: Icons.history_rounded,
                color: color,
                selected: selected == yesterday,
                onTap: () => setSheet(() => selected = yesterday),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: color),
          ),
          child: CalendarDatePicker(
            key: ValueKey(selected),
            initialDate: selected,
            firstDate: first,
            lastDate: last,
            onDateChanged: (d) {
              AppHaptics.select();
              setSheet(() => selected = d);
            },
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: '${l10n.done} · ${Formatters.fullDate(selected)}',
          icon: Icons.check_rounded,
          color: accent,
          onPressed: () => Navigator.pop(context, selected),
        ),
      ],
    ),
  );
}
