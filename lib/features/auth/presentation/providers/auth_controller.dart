import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/services/logger_service.dart';
import '../../../categories/domain/category_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

/// Session state. `null` = logged out. Persisted across restarts by the
/// repository, so the session never expires until the user logs out.
class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._ref) : super(null);
  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);
  CategoryRepository get _categories => _ref.read(categoryRepositoryProvider);
  LoggerService get _log => _ref.read(loggerProvider);

  /// Writes a trackable user profile to Firestore (`users/{id}`) so every user
  /// can be identified by phone / email / name. No-op when Firestore is off.
  void _syncProfile(AppUser user) {
    final db = _ref.read(firestoreProvider);
    if (db == null) return;
    db.collection(AppConstants.cUsers).doc(user.id).set({
      'id': user.id,
      'phone': user.phone,
      'email': user.email,
      'name': user.fullName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((Object _) {});
  }

  /// Called once at startup to restore any persisted session.
  Future<void> restore() async {
    state = await _repo.currentUser();
    if (state != null) {
      await _categories.ensureSeeded(state!.id);
      _syncProfile(state!);
    }
  }

  Future<void> login({required String phone, required String password}) async {
    final user = await _repo.login(phone: phone, password: password);
    await _categories.ensureSeeded(user.id);
    _log.log('login success', area: 'auth');
    _ref.read(analyticsServiceProvider).logEvent('login');
    state = user;
    _syncProfile(user);
  }

  Future<void> register({
    required String phone,
    required String password,
    String? fullName,
    String? email,
    DateTime? dob,
    String? state,
  }) async {
    final user = await _repo.register(
      phone: phone,
      password: password,
      fullName: fullName,
      email: email,
      dob: dob,
      state: state,
    );
    await _categories.ensureSeeded(user.id);
    _log.log('register success', area: 'auth');
    _ref.read(analyticsServiceProvider).logEvent('sign_up');
    this.state = user;
    _syncProfile(user);
  }

  Future<void> logout() async {
    await _repo.logout();
    _ref.read(analyticsServiceProvider).logEvent('logout');
    state = null;
  }

  /// Delete the signed-in account after verifying the password.
  Future<void> deleteAccount(String password) async {
    final current = state;
    if (current == null) return;
    await _repo.deleteAccount(userId: current.id, password: password);
    _ref.read(analyticsServiceProvider).logEvent('delete_account');
    state = null;
  }

  /// Google returning-user path: log in if an account with [email] exists.
  Future<bool> loginByEmail(String email) async {
    final user = await _repo.loginByEmail(email);
    if (user == null) return false;
    state = user;
    await _categories.ensureSeeded(user.id);
    _ref.read(analyticsServiceProvider).logEvent('login_google');
    _syncProfile(user);
    return true;
  }

  /// How many accounts share this Google email (0 new, 1 returning, >1 ambiguous).
  Future<List<AppUser>> usersByEmail(String email) => _repo.usersByEmail(email);

  /// Complete a Google sign-up once the phone is verified via OTP.
  Future<void> resolveGoogleSignup({
    required String email,
    required String phone,
    String? fullName,
    String? password,
  }) async {
    final user = await _repo.resolveGoogleSignup(
      email: email,
      phone: phone,
      fullName: fullName,
      password: password,
    );
    state = user;
    await _categories.ensureSeeded(user.id);
    _ref.read(analyticsServiceProvider).logEvent('google_signup');
    _syncProfile(user);
  }

  /// Links a Google-verified email to the current account (no email OTP).
  /// Enforces one-email-to-one-phone. Returns null on success, else an error
  /// message key to show the user.
  Future<String?> linkGoogleEmail(String googleEmail, String? googleName) async {
    final user = state;
    if (user == null) return 'somethingWrong';
    final email = googleEmail.trim();
    if (email.isEmpty) return 'somethingWrong';

    // 1 email : 1 phone — reject if this email is on a different account.
    final existing = await _repo.usersByEmail(email);
    if (existing.any((u) => u.id != user.id)) return 'emailLinkedElsewhere';

    // If a different email is already on this profile, don't silently replace.
    final current = (user.email ?? '').trim().toLowerCase();
    if (current.isNotEmpty && current != email.toLowerCase()) {
      return 'emailMismatchProfile';
    }

    final updated = user.copyWith(
      email: email,
      emailVerified: true,
      fullName: (user.fullName == null || user.fullName!.isEmpty)
          ? googleName
          : user.fullName,
    );
    state = await _repo.updateProfile(updated);
    _syncProfile(state!);
    return null;
  }

  /// "Forgot password" — remembered path: true if [password] still matches.
  Future<bool> verifyPassword(String phone, String password) =>
      _repo.verifyPassword(phone: phone, password: password);

  /// Whether the signed-in user has a password set (false for Google-only
  /// accounts that never set one).
  Future<bool> hasPassword() {
    final user = state;
    if (user == null) return Future.value(false);
    return _repo.hasPassword(user.id);
  }

  /// Settings → Security → Change Password.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = state;
    if (user == null) return;
    await _repo.changePassword(
      userId: user.id,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    _log.log('password changed', area: 'auth');
  }

  /// Settings → Google → Change Google. Unlike [linkGoogleEmail], this
  /// replaces whatever Google email is already linked (after the user has
  /// re-authenticated with the new Google account). No OTP.
  Future<String?> changeGoogleEmail(
      String newGoogleEmail, String? googleName) async {
    final user = state;
    if (user == null) return 'somethingWrong';
    final email = newGoogleEmail.trim();
    if (email.isEmpty) return 'somethingWrong';

    final existing = await _repo.usersByEmail(email);
    if (existing.any((u) => u.id != user.id)) return 'emailLinkedElsewhere';

    final updated = user.copyWith(email: email, emailVerified: true);
    state = await _repo.updateProfile(updated);
    _log.log('google account changed', area: 'auth');
    _syncProfile(state!);
    return null;
  }

  /// Settings → Google → Remove Google. Only allowed once the account has a
  /// password, so mobile + password always remains a valid way back in.
  /// Returns null on success, or an error message key.
  Future<String?> removeGoogleLink() async {
    final user = state;
    if (user == null) return 'somethingWrong';
    if (!(await _repo.hasPassword(user.id))) return 'setPasswordFirst';
    final updated = user.copyWith(email: '', emailVerified: false);
    state = await _repo.updateProfile(updated);
    _log.log('google account removed', area: 'auth');
    _syncProfile(state!);
    return null;
  }

  /// Save edited profile fields for the signed-in user.
  Future<void> updateProfile({
    String? fullName,
    String? email,
    DateTime? dob,
    String? state,
  }) async {
    final current = this.state;
    if (current == null) return;
    final updated = current.copyWith(
      fullName: fullName,
      email: email,
      dob: dob,
      state: state,
    );
    this.state = await _repo.updateProfile(updated);
    _ref.read(analyticsServiceProvider).logEvent('profile_update');
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AppUser?>(
  (ref) => AuthController(ref),
);
