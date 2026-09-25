import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'notes_providers.dart';

/// A simple notepad: card view of notes (optional title + body), each stamped
/// with date + time.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notes)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fabNotes',
        onPressed: () => _editSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addNote),
      ),
      body: SafeArea(
        child: notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sticky_note_2_outlined,
                        size: 56, color: context.semantic.muted),
                    const SizedBox(height: 12),
                    Text(l10n.noNotes,
                        style: TextStyle(color: context.semantic.muted)),
                  ],
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final n = notes[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _editSheet(context, ref,
                              id: n.id, title: n.title, text: n.text),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.event_note_outlined,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        Formatters.dateDayTime(n.updatedAt),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: context.semantic.muted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        final ok = await showAppConfirm(
                                          context,
                                          icon: Icons.delete_outline,
                                          title: l10n.delete,
                                          message: n.title.isNotEmpty
                                              ? n.title
                                              : n.text,
                                          confirmLabel: l10n.delete,
                                          danger: true,
                                        );
                                        if (ok) {
                                          await ref
                                              .read(notesProvider.notifier)
                                              .remove(n.id);
                                        }
                                      },
                                      child: Icon(Icons.close_rounded,
                                          size: 16,
                                          color: context.semantic.muted),
                                    ),
                                  ],
                                ),
                                if (n.title.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(n.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                ],
                                const SizedBox(height: 6),
                                Text(n.text,
                                    style: const TextStyle(height: 1.4)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _editSheet(BuildContext context, WidgetRef ref,
      {String? id, String? title, String? text}) async {
    final l10n = AppLocalizations.of(context);
    final titleC = TextEditingController(text: title ?? '');
    final bodyC = TextEditingController(text: text ?? '');
    await showAppSheet<void>(
      context,
      title: id == null ? l10n.addNote : l10n.notes,
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleC,
            decoration: InputDecoration(
              labelText: '${l10n.name} (${l10n.optional})',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyC,
            maxLines: 6,
            minLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.noteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: l10n.save,
            icon: Icons.check_rounded,
            onPressed: () {
              final t = bodyC.text.trim();
              if (t.isEmpty) {
                Navigator.pop(context);
                return;
              }
              final notifier = ref.read(notesProvider.notifier);
              if (id == null) {
                notifier.add(t, title: titleC.text.trim());
              } else {
                notifier.update(id, t, title: titleC.text.trim());
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
