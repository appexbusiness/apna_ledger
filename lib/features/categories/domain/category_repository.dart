import 'category.dart';

abstract interface class CategoryRepository {
  Stream<List<Category>> watch(String userId);
  Future<List<Category>> fetch(String userId);
  Future<void> upsert(String userId, Category category);
  Future<void> delete(String userId, String id);

  /// Seeds the default categories for a brand-new user (idempotent).
  Future<void> ensureSeeded(String userId);
}
