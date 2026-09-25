import 'dart:async';
import 'dart:convert';
import '../../../core/services/local_storage_service.dart';
import '../domain/category.dart';
import '../domain/category_repository.dart';
import 'default_categories.dart';

class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository(this._storage);
  final LocalStorageService _storage;

  final _controllers = <String, StreamController<List<Category>>>{};
  String _key(String userId) => 'cats_$userId';

  List<Category> _read(String userId) {
    final raw = _storage.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _write(String userId, List<Category> items) async {
    await _storage.setString(
      _key(userId),
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
    _controllers[userId]?.add(items);
  }

  @override
  Future<void> ensureSeeded(String userId) async {
    if (_read(userId).isNotEmpty) return;
    await _write(userId, DefaultCategories.build());
  }

  @override
  Stream<List<Category>> watch(String userId) {
    final controller = _controllers.putIfAbsent(
      userId,
      () => StreamController<List<Category>>.broadcast(),
    );
    scheduleMicrotask(() => controller.add(_read(userId)));
    return controller.stream;
  }

  @override
  Future<List<Category>> fetch(String userId) async => _read(userId);

  @override
  Future<void> upsert(String userId, Category category) async {
    final items = _read(userId);
    final idx = items.indexWhere((e) => e.id == category.id);
    if (idx == -1) {
      items.add(category);
    } else {
      items[idx] = category;
    }
    await _write(userId, items);
  }

  @override
  Future<void> delete(String userId, String id) async {
    final items = _read(userId)..removeWhere((e) => e.id == id);
    await _write(userId, items);
  }
}
