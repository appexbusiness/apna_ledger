import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injector.dart';
import '../../../core/services/local_storage_service.dart';
import '../domain/savings_goal.dart';

const _kGoals = 'savings_goals';

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<SavingsGoal>>((ref) {
  return GoalsNotifier(ref.watch(localStorageProvider));
});

class GoalsNotifier extends StateNotifier<List<SavingsGoal>> {
  GoalsNotifier(this._storage) : super(_load(_storage));
  final LocalStorageService _storage;

  static List<SavingsGoal> _load(LocalStorageService s) {
    final raw = s.getString(_kGoals);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SavingsGoal.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() =>
      _storage.setString(_kGoals, jsonEncode(state.map((e) => e.toMap()).toList()));

  Future<void> add(String name, double target, {DateTime? dueDate}) async {
    state = [
      ...state,
      SavingsGoal(
          id: const Uuid().v4(), name: name, target: target, dueDate: dueDate),
    ];
    await _persist();
  }

  Future<void> addSaved(String id, double amount) async {
    state = [
      for (final g in state)
        if (g.id == id) g.copyWith(saved: g.saved + amount) else g,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((g) => g.id != id).toList();
    await _persist();
  }
}
