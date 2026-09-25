import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injector.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../domain/category.dart';

final categoriesStreamProvider =
    StreamProvider.autoDispose<List<Category>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId.isEmpty) return const Stream.empty();
  return ref.watch(categoryRepositoryProvider).watch(userId);
});

/// Fast lookup by id for rendering names/icons in lists.
final categoryByIdProvider =
    Provider.autoDispose<Map<String, Category>>((ref) {
  final list = ref.watch(categoriesStreamProvider).value ?? const [];
  return {for (final c in list) c.id: c};
});

/// The category new transactions default to ("Others", else the first).
final defaultCategoryIdProvider = Provider.autoDispose<String?>((ref) {
  final list = ref.watch(categoriesStreamProvider).value ?? const [];
  if (list.isEmpty) return null;
  final others =
      list.where((c) => c.name.toLowerCase() == 'others').toList();
  return others.isNotEmpty ? others.first.id : list.first.id;
});

final categoryActionsProvider = Provider((ref) => CategoryActions(ref));

class CategoryActions {
  CategoryActions(this._ref);
  final Ref _ref;

  Future<void> save(Category category) {
    final userId = _ref.read(currentUserIdProvider);
    return _ref.read(categoryRepositoryProvider).upsert(userId, category);
  }

  Future<void> delete(String id) {
    final userId = _ref.read(currentUserIdProvider);
    return _ref.read(categoryRepositoryProvider).delete(userId, id);
  }
}
