import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/category.dart';
import '../domain/category_repository.dart';
import 'default_categories.dart';

/// Production implementation. Layout: users/{userId}/categories/{categoryId}
class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _db
      .collection(AppConstants.cUsers)
      .doc(userId)
      .collection(AppConstants.cCategories);

  @override
  Future<void> ensureSeeded(String userId) async {
    final existing = await _col(userId).limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final c in DefaultCategories.build()) {
      batch.set(_col(userId).doc(c.id), c.toMap());
    }
    await batch.commit();
  }

  @override
  Stream<List<Category>> watch(String userId) => _col(userId)
      .snapshots()
      .map((s) => s.docs.map((d) => Category.fromMap(d.data())).toList());

  @override
  Future<List<Category>> fetch(String userId) async {
    final snap = await _col(userId).get();
    return snap.docs.map((d) => Category.fromMap(d.data())).toList();
  }

  @override
  Future<void> upsert(String userId, Category category) =>
      _col(userId).doc(category.id).set(category.toMap());

  @override
  Future<void> delete(String userId, String id) =>
      _col(userId).doc(id).delete();
}
