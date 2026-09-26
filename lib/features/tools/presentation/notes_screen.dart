import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/quick_note.dart';
import 'notes_providers.dart';

/// A simple notepad: card view of notes (optional title + body), each stamped
/// with date + time. Swipe a note to delete it; tap to edit.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  static const _accents = [
    Color(0xFFE9A20F),
    AppColors.primary,
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(notesProvider);

    return Scaffold(
      floatingActionButton: _AddFab(
        label: l10n.addNote,
        onTap: () => _editSheet(context, ref),
      ),
      body: AmbientBackground(
        tint: const Color(0xFFE9A20F),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 110),
                children: [
                  ScreenHeader(
                    title: l10n.notes,
                    subtitle: '${notes.length}',
                    onBack: () => context.pop(),
                  ),
                  if (notes.isEmpty)
                    EmptyState(
                      glyph: FinGlyph.notes,
                      title: l10n.noNotes,
                      actionLabel: l10n.addNote,
                      onAction: () => _editSheet(context, ref),
                    )
                  else
                    for (var i = 0; i < notes.length; i++)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                        child: Entrance(
                          index: i,
                          child: _NoteCard(
                            note: notes[i],
                            color: _accents[i % _accents.length],
                            onTap: () => _editSheet(context, ref, note: notes[i]),
                            onDelete: () => _delete(context, ref, notes[i]),
                          ),
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

  Future<bool> _delete(BuildContext context, WidgetRef ref, QuickNote n) async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    final ok = await showAppConfirm(
      context,
      icon: Icons.delete_rounded,
      title: l10n.delete,
      message: n.title.isNotEmpty ? n.title : n.text,
      confirmLabel: l10n.delete,
      danger: true,
    );
    if (ok) {
      await ref.read(notesProvider.notifier).remove(n.id);
      toast.success(l10n.deletedToast);
    }
    return false; // the list rebuilds from the provider
  }

  Future<void> _editSheet(
    BuildContext context,
    WidgetRef ref, {
    QuickNote? note,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    final titleC = TextEditingController(text: note?.title ?? '');
    final bodyC = TextEditingController(text: note?.text ?? '');
    final saved = await showAppSheet<bool>(
      context,
      title: note == null ? l10n.addNote : l10n.notes,
      subtitle: note == null ? null : Formatters.dateDayTime(note.updatedAt),
      glyph: FinGlyph.notes,
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: titleC,
            label: '${l10n.name} (${l10n.optional})',
            icon: Icons.title_rounded,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: bodyC,
            label: l10n.noteHint,
            icon: Icons.notes_rounded,
            maxLines: 8,
            minLines: 4,
            autofocus: note == null,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 18),
          AppButton(
            label: l10n.save,
            icon: Icons.check_rounded,
            variant: AppButtonVariant.gold,
            onPressed: () {
              final t = bodyC.text.trim();
              if (t.isEmpty) {
                Navigator.pop(context, false);
                return;
              }
              final notifier = ref.read(notesProvider.notifier);
              if (note == null) {
                notifier.add(t, title: titleC.text.trim());
              } else {
                notifier.update(note.id, t, title: titleC.text.trim());
              }
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
    if (saved == true) toast.success(l10n.savedToast);
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  final QuickNote note;
  final Color color;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon3D(icon: Icons.delete_rounded, color: semantic.expense, size: 38),
      ),
      child: Surface3D(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(22),
                  ),
                  color: color,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              Formatters.dateDayTime(note.updatedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: semantic.muted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(Icons.close_rounded,
                                size: 18, color: semantic.muted,),
                          ),
                        ],
                      ),
                      if (note.title.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          note.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        note.text,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extended floating action used on tool screens (outside the main shell).
class _AddFab extends StatelessWidget {
  const _AddFab({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: Icons.add_rounded,
      variant: AppButtonVariant.gold,
      expand: false,
      onPressed: onTap,
    );
  }
}
