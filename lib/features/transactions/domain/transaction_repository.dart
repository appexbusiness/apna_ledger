import 'transaction.dart';

abstract interface class TransactionRepository {
  /// Live stream of a user's transactions, newest first.
  Stream<List<TxnEntry>> watch(String userId);
  Future<List<TxnEntry>> fetch(String userId);
  Future<void> upsert(TxnEntry entry);
  Future<void> delete(String userId, String id);
}
