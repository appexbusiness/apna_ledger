import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/services/local_storage_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Demo backend for auth backed by SharedPreferences.
///
/// This lets the app run end-to-end today (register → OTP → login → stay logged
/// in → logout) without any server. When the real OTP/API backend is ready,
/// implement [AuthRepository] against it and swap the binding in the injector —
/// nothing in the UI changes.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._storage);

  final LocalStorageService _storage;
  static const _uuid = Uuid();

  String _hash(String password) =>
      sha256.convert(utf8.encode('apnaledger::$password')).toString();

  List<Map<String, dynamic>> _readUsers() {
    final raw = _storage.getString(AppConstants.kUsersBox);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _writeUsers(List<Map<String, dynamic>> users) =>
      _storage.setString(AppConstants.kUsersBox, jsonEncode(users));

  @override
  Future<AppUser?> currentUser() async {
    final raw = _storage.getString(AppConstants.kSessionUser);
    if (raw == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> _persistSession(AppUser user) =>
      _storage.setString(AppConstants.kSessionUser, jsonEncode(user.toMap()));

  @override
  Future<bool> phoneExists(String phone) async =>
      _readUsers().any((u) => u['phone'] == phone);

  @override
  Future<AppUser?> loginByEmail(String email) async {
    final needle = email.trim().toLowerCase();
    if (needle.isEmpty) return null;
    final match = _readUsers()
        .where((u) => (u['email'] as String?)?.toLowerCase() == needle)
        .toList();
    if (match.isEmpty) return null;
    final user = AppUser.fromMap(Map<String, dynamic>.from(match.first));
    await _persistSession(user);
    return user;
  }

  @override
  Future<List<AppUser>> usersByEmail(String email) async {
    final needle = email.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return _readUsers()
        .where((u) => (u['email'] as String?)?.toLowerCase() == needle)
        .map((u) => AppUser.fromMap(Map<String, dynamic>.from(u)))
        .toList();
  }

  @override
  Future<AppUser> resolveGoogleSignup({
    required String email,
    required String phone,
    String? fullName,
    String? password,
  }) async {
    final users = _readUsers();
    final e = email.trim().toLowerCase();

    // 1) Exact (email + phone) already linked → log in.
    final exact = users.indexWhere((u) =>
        u['phone'] == phone &&
        (u['email'] as String?)?.toLowerCase() == e);
    if (exact != -1) {
      final user = AppUser.fromMap(Map<String, dynamic>.from(users[exact]));
      await _persistSession(user);
      return user;
    }

    // 2) Phone already exists → map this Google email onto it → log in.
    final byPhone = users.indexWhere((u) => u['phone'] == phone);
    if (byPhone != -1) {
      users[byPhone]['email'] = email;
      users[byPhone]['emailVerified'] = true;
      final existingName = users[byPhone]['fullName'] as String?;
      if ((existingName == null || existingName.isEmpty) &&
          (fullName != null && fullName.isNotEmpty)) {
        users[byPhone]['fullName'] = fullName;
      }
      await _writeUsers(users);
      final user =
          AppUser.fromMap(Map<String, dynamic>.from(users[byPhone]));
      await _persistSession(user);
      return user;
    }

    // 3) Brand-new account.
    final user = AppUser(
      id: _uuid.v4(),
      phone: phone,
      email: email,
      fullName: fullName,
      emailVerified: true,
    );
    final map = <String, dynamic>{...user.toMap()};
    if (password != null && password.isNotEmpty) {
      map['passwordHash'] = _hash(password);
    }
    users.add(map);
    await _writeUsers(users);
    await _persistSession(user);
    return user;
  }

  @override
  Future<void> deleteAccount({
    required String userId,
    required String password,
  }) async {
    final users = _readUsers();
    final idx = users.indexWhere((u) => u['id'] == userId);
    if (idx == -1) throw const AppFailure('somethingWrong');
    final hash = users[idx]['passwordHash'];
    // Google-only accounts may have no password hash; those can delete freely.
    if (hash != null && hash != _hash(password)) {
      throw const AppFailure('loginFailed');
    }
    users.removeAt(idx);
    await _writeUsers(users);
    await _storage.remove(AppConstants.kSessionUser);
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final users = _readUsers();
    final idx = users.indexWhere((u) => u['id'] == user.id);
    if (idx == -1) throw const AppFailure('somethingWrong');
    // Preserve the password hash while replacing the profile fields.
    final passwordHash = users[idx]['passwordHash'];
    users[idx] = {...user.toMap(), 'passwordHash': passwordHash};
    await _writeUsers(users);
    await _persistSession(user);
    return user;
  }

  @override
  Future<AppUser> register({
    required String phone,
    required String password,
    String? fullName,
    String? email,
    DateTime? dob,
    String? state,
  }) async {
    final users = _readUsers();
    if (users.any((u) => u['phone'] == phone)) {
      throw const AppFailure('accountExists');
    }
    final user = AppUser(
      id: _uuid.v4(),
      phone: phone,
      fullName: fullName,
      email: email,
      dob: dob,
      state: state,
    );
    users.add({...user.toMap(), 'passwordHash': _hash(password)});
    await _writeUsers(users);
    await _persistSession(user);
    return user;
  }

  @override
  Future<AppUser> login({
    required String phone,
    required String password,
  }) async {
    final match = _readUsers().where((u) => u['phone'] == phone).toList();
    if (match.isEmpty || match.first['passwordHash'] != _hash(password)) {
      throw const AppFailure('loginFailed');
    }
    final user = AppUser.fromMap(match.first);
    await _persistSession(user);
    return user;
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    final users = _readUsers();
    final idx = users.indexWhere((u) => u['phone'] == phone);
    if (idx == -1) throw const AppFailure('somethingWrong');
    users[idx]['passwordHash'] = _hash(newPassword);
    await _writeUsers(users);
  }

  @override
  Future<bool> verifyPassword({
    required String phone,
    required String password,
  }) async {
    final match = _readUsers().where((u) => u['phone'] == phone).toList();
    if (match.isEmpty) return false;
    return match.first['passwordHash'] == _hash(password);
  }

  @override
  Future<bool> hasPassword(String userId) async {
    final match = _readUsers().where((u) => u['id'] == userId).toList();
    if (match.isEmpty) return false;
    final hash = match.first['passwordHash'] as String?;
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final users = _readUsers();
    final idx = users.indexWhere((u) => u['id'] == userId);
    if (idx == -1) throw const AppFailure('somethingWrong');
    final hash = users[idx]['passwordHash'] as String?;
    if (hash != null && hash.isNotEmpty && hash != _hash(oldPassword)) {
      throw const AppFailure('loginFailed');
    }
    users[idx]['passwordHash'] = _hash(newPassword);
    await _writeUsers(users);
  }

  @override
  Future<void> logout() => _storage.remove(AppConstants.kSessionUser);
}
