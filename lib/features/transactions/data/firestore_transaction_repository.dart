import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';

/// Production implementation. Layout:
///   users/{userId}/transactions/{txnId}
///
/// To switch the app onto Firebase, bind this in `injector.dart` instead of
/// [LocalTransactionRepository]. No other code changes.
class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _db
      .collection(AppConstants.cUsers)
      .doc(userId)
      .collection(AppConstants.cTransactions);

  @override
  Stream<List<TxnEntry>> watch(String userId) => _col(userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => TxnEntry.fromMap(d.data())).toList());

  @override
  Future<List<TxnEntry>> fetch(String userId) async {
    final snap =
        await _col(userId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => TxnEntry.fromMap(d.data())).toList();
  }

  @override
  Future<void> upsert(TxnEntry entry) =>
      _col(entry.userId).doc(entry.id).set(entry.toMap());

  @override
  Future<void> delete(String userId, String id) =>
      _col(userId).doc(id).delete();
}
