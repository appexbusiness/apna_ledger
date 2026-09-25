import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/services/local_storage_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Cross-device auth backed by Firestore. Users live in `app_users` keyed by
/// phone number (so the same number can never be registered twice, and login
/// works from any device). The session (stay-logged-in) is kept locally.
class FirestoreAuthRepository implements AuthRepository {
  FirestoreAuthRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final LocalStorageService _storage;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('app_users');

  String _hash(String password) =>
      sha256.convert(utf8.encode('apnaledger::$password')).toString();

  Map<String, dynamic> _record(AppUser u, {String? passwordHash}) => {
        ...u.toMap(),
        'emailLower': (u.email ?? '').toLowerCase(),
        if (passwordHash != null) 'passwordHash': passwordHash,
      };

  Future<void> _persistSession(AppUser user) =>
      _storage.setString(AppConstants.kSessionUser, jsonEncode(user.toMap()));

  @override
  Future<AppUser?> currentUser() async {
    final raw = _storage.getString(AppConstants.kSessionUser);
    if (raw == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  @override
  Future<void> logout() => _storage.remove(AppConstants.kSessionUser);

  @override
  Future<bool> phoneExists(String phone) async =>
      (await _col.doc(phone).get()).exists;

  @override
  Future<AppUser> register({
    required String phone,
    required String password,
    String? fullName,
    String? email,
    DateTime? dob,
    String? state,
  }) async {
    final existing = await _col.doc(phone).get();
    if (existing.exists) throw const AppFailure('accountExists');
    final user = AppUser(
      id: _uuid.v4(),
      phone: phone,
      fullName: fullName,
      email: email,
      dob: dob,
      state: state,
    );
    await _col.doc(phone).set(_record(user, passwordHash: _hash(password)));
    await _persistSession(user);
    return user;
  }

  @override
  Future<AppUser> login({
    required String phone,
    required String password,
  }) async {
    final snap = await _col.doc(phone).get();
    final data = snap.data();
    if (data == null || data['passwordHash'] != _hash(password)) {
      throw const AppFailure('loginFailed');
    }
    final user = AppUser.fromMap(Map<String, dynamic>.from(data));
    await _persistSession(user);
    return user;
  }

  @override
  Future<AppUser?> loginByEmail(String email) async {
    final needle = email.trim().toLowerCase();
    if (needle.isEmpty) return null;
    final q = await _col.where('emailLower', isEqualTo: needle).limit(1).get();
    if (q.docs.isEmpty) return null;
    final user = AppUser.fromMap(Map<String, dynamic>.from(q.docs.first.data()));
    await _persistSession(user);
    return user;
  }

  @override
  Future<List<AppUser>> usersByEmail(String email) async {
    final needle = email.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final q = await _col.where('emailLower', isEqualTo: needle).get();
    return q.docs
        .map((d) => AppUser.fromMap(Map<String, dynamic>.from(d.data())))
        .toList();
  }

  @override
  Future<AppUser> resolveGoogleSignup({
    required String email,
    required String phone,
    String? fullName,
    String? password,
  }) async {
    final snap = await _col.doc(phone).get();
    if (snap.exists) {
      // Phone doc exists → link the Google email onto it and log in.
      final data = Map<String, dynamic>.from(snap.data()!);
      data['email'] = email;
      data['emailLower'] = email.toLowerCase();
      data['emailVerified'] = true;
      if (((data['fullName'] as String?) ?? '').isEmpty &&
          (fullName != null && fullName.isNotEmpty)) {
        data['fullName'] = fullName;
      }
      await _col.doc(phone).set(data);
      final user = AppUser.fromMap(data);
      await _persistSession(user);
      return user;
    }
    final user = AppUser(
      id: _uuid.v4(),
      phone: phone,
      email: email,
      fullName: fullName,
      emailVerified: true,
    );
    await _col.doc(phone).set(_record(
          user,
          passwordHash: (password != null && password.isNotEmpty)
              ? _hash(password)
              : null,
        ));
    await _persistSession(user);
    return user;
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final ref = _col.doc(user.phone);
    final snap = await ref.get();
    if (!snap.exists) throw const AppFailure('somethingWrong');
    final data = Map<String, dynamic>.from(snap.data()!);
    final merged = {
      ...data,
      ..._record(user),
    };
    await ref.set(merged);
    await _persistSession(user);
    return user;
  }

  @override
  Future<void> deleteAccount({
    required String userId,
    required String password,
  }) async {
    final q = await _col.where('id', isEqualTo: userId).limit(1).get();
    if (q.docs.isEmpty) throw const AppFailure('somethingWrong');
    final doc = q.docs.first;
    final hash = doc.data()['passwordHash'];
    if (hash != null && hash != _hash(password)) {
      throw const AppFailure('loginFailed');
    }
    await doc.reference.delete();
    await _storage.remove(AppConstants.kSessionUser);
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    final ref = _col.doc(phone);
    if (!(await ref.get()).exists) throw const AppFailure('somethingWrong');
    await ref.update({'passwordHash': _hash(newPassword)});
  }

  @override
  Future<bool> verifyPassword({
    required String phone,
    required String password,
  }) async {
    final snap = await _col.doc(phone).get();
    final data = snap.data();
    if (data == null) return false;
    return data['passwordHash'] == _hash(password);
  }

  @override
  Future<bool> hasPassword(String userId) async {
    final q = await _col.where('id', isEqualTo: userId).limit(1).get();
    if (q.docs.isEmpty) return false;
    final hash = q.docs.first.data()['passwordHash'] as String?;
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final q = await _col.where('id', isEqualTo: userId).limit(1).get();
    if (q.docs.isEmpty) throw const AppFailure('somethingWrong');
    final doc = q.docs.first;
    final hash = doc.data()['passwordHash'] as String?;
    if (hash != null && hash.isNotEmpty && hash != _hash(oldPassword)) {
      throw const AppFailure('loginFailed');
    }
    await doc.reference.update({'passwordHash': _hash(newPassword)});
  }
}
