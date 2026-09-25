import 'dart:async';
import 'dart:convert';
import '../../../core/services/local_storage_service.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';

/// SharedPreferences-backed store so the app is fully usable offline / in demos.
/// The production path uses [FirestoreTransactionRepository] — same interface.
class LocalTransactionRepository implements TransactionRepository {
  LocalTransactionRepository(this._storage);
  final LocalStorageService _storage;

  final _controllers = <String, StreamController<List<TxnEntry>>>{};

  String _key(String userId) => 'txns_$userId';

  List<TxnEntry> _read(String userId) {
    final raw = _storage.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    final items = list
        .map((e) => TxnEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> _write(String userId, List<TxnEntry> items) async {
    await _storage.setString(
      _key(userId),
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
    _emit(userId);
  }

  void _emit(String userId) {
    _controllers[userId]?.add(_read(userId));
  }

  @override
  Stream<List<TxnEntry>> watch(String userId) {
    final controller = _controllers.putIfAbsent(
      userId,
      () => StreamController<List<TxnEntry>>.broadcast(),
    );
    scheduleMicrotask(() => controller.add(_read(userId)));
    return controller.stream;
  }

  @override
  Future<List<TxnEntry>> fetch(String userId) async => _read(userId);

  @override
  Future<void> upsert(TxnEntry entry) async {
    final items = _read(entry.userId);
    final idx = items.indexWhere((e) => e.id == entry.id);
    if (idx == -1) {
      items.add(entry);
    } else {
      items[idx] = entry;
    }
    await _write(entry.userId, items);
  }

  @override
  Future<void> delete(String userId, String id) async {
    final items = _read(userId)..removeWhere((e) => e.id == id);
    await _write(userId, items);
  }
}
