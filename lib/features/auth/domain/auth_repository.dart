import 'app_user.dart';

/// Contract for authentication. The presentation layer only ever talks to
/// this interface, so swapping the demo backend for a real OTP/API backend
/// later is a one-file change (no UI edits).
abstract interface class AuthRepository {
  /// Returns the persisted session user, or null if logged out.
  Future<AppUser?> currentUser();

  Future<AppUser> login({required String phone, required String password});

  Future<AppUser> register({
    required String phone,
    required String password,
    String? fullName,
    String? email,
    DateTime? dob,
    String? state,
  });

  Future<bool> phoneExists(String phone);

  /// Persists edited profile fields for the current user and returns the
  /// updated record (also refreshes the saved session).
  Future<AppUser> updateProfile(AppUser user);

  /// If a user with [email] exists, starts their session and returns it (used
  /// by "Continue with Google" for returning users). Returns null otherwise.
  Future<AppUser?> loginByEmail(String email);

  /// All users that have this email (0 = new, 1 = returning, >1 = ambiguous).
  Future<List<AppUser>> usersByEmail(String email);

  /// Reconciles a Google sign-up with a verified phone:
  ///  • (email+phone) already exists → log in
  ///  • phone exists (any email) → map the email onto it → log in
  ///  • otherwise → create a new account.
  Future<AppUser> resolveGoogleSignup({
    required String email,
    required String phone,
    String? fullName,
    String? password,
  });

  /// Permanently removes the user's account (after verifying [password]) and
  /// clears the session.
  Future<void> deleteAccount({
    required String userId,
    required String password,
  });

  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  });

  /// True when [password] matches the account on [phone]. Used by "Forgot
  /// password" when the user says they still remember it — lets them reset
  /// directly, with no OTP needed.
  Future<bool> verifyPassword({
    required String phone,
    required String password,
  });

  /// Whether the account has a password set at all (Google-only accounts
  /// created without one do not). Removing a linked Google account is only
  /// allowed once a password exists, so the user always has a way back in.
  Future<bool> hasPassword(String userId);

  /// Changes the password for a signed-in user after verifying [oldPassword].
  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  });

  Future<void> logout();
}
