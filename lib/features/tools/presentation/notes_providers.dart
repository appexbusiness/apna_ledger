import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injector.dart';
import '../../../core/services/local_storage_service.dart';
import '../domain/quick_note.dart';

const _kNotes = 'quick_notes';

final notesProvider =
    StateNotifierProvider<NotesNotifier, List<QuickNote>>((ref) {
  return NotesNotifier(ref.watch(localStorageProvider));
});

class NotesNotifier extends StateNotifier<List<QuickNote>> {
  NotesNotifier(this._storage) : super(_load(_storage));
  final LocalStorageService _storage;

  static List<QuickNote> _load(LocalStorageService s) {
    final raw = s.getString(_kNotes);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      final notes = list
          .map((e) => QuickNote.fromMap(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() => _storage.setString(
      _kNotes, jsonEncode(state.map((e) => e.toMap()).toList()));

  Future<void> add(String text, {String title = ''}) async {
    final now = DateTime.now();
    state = [
      QuickNote(
          id: const Uuid().v4(),
          title: title,
          text: text,
          createdAt: now,
          updatedAt: now),
      ...state,
    ];
    await _persist();
  }

  Future<void> update(String id, String text, {String title = ''}) async {
    final now = DateTime.now();
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(title: title, text: text, updatedAt: now)
        else
          n,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _persist();
  }
}
