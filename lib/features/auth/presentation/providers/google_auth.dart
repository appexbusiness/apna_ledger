import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Result of a Google sign-in used to pre-fill / verify. Phone + OTP is still
/// required for a brand-new account (per product rules).
class GooglePrefill {
  const GooglePrefill({this.name, this.email, this.photoUrl});
  final String? name;
  final String? email;
  final String? photoUrl;
}

/// Outcome of a Google popup: an account, a user-cancel, or a friendly error
/// message (the raw error is logged to the console for debugging).
class GoogleResult {
  const GoogleResult({this.account, this.error, this.cancelled = false});
  final GooglePrefill? account;
  final String? error;
  final bool cancelled;

  bool get ok => account != null;
}

/// Carries the chosen Google account into the register screen.
final googlePrefillProvider = StateProvider<GooglePrefill?>((ref) => null);

final googleSignInServiceProvider = Provider((ref) => GoogleSignInService());

class GoogleSignInService {
  final GoogleSignIn _google = GoogleSignIn(scopes: const ['email', 'profile']);

  /// Always shows Google's account chooser — even if the browser/device
  /// already has a session for one account — so the user can pick a
  /// different one instead of being silently signed in with whichever
  /// account Chrome/Play Services already has cached.
  Future<GoogleResult> pick() async {
    try {
      // Drop any cached session first so signIn() can't short-circuit
      // straight back into it without showing the chooser.
      await _google.signOut();
      final account = await _google.signIn();
      if (account == null) return const GoogleResult(cancelled: true);
      return GoogleResult(
        account: GooglePrefill(
          name: account.displayName,
          email: account.email,
          photoUrl: account.photoUrl,
        ),
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e'); // raw, for debugging
      return GoogleResult(error: _friendly(e.toString()));
    }
  }

  /// Turns raw plugin/network errors into a calm, user-facing sentence.
  String _friendly(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('popup') || r.contains('closed') || r.contains('cancel')) {
      return 'Google sign-in was cancelled. Please try again.';
    }
    if (r.contains('fedcm') || r.contains('networkerror') ||
        r.contains('accounts list is empty')) {
      // Chrome blocks Google's FedCM/One Tap prompt in Incognito and some
      // "block third-party sign-in" privacy settings — this is the most
      // common cause of a silent/looping failure on web.
      return 'Google sign-in didn’t load. If you’re in an Incognito/Private '
          'window, try a normal window, or allow third-party sign-in for '
          'this site in Chrome settings.';
    }
    if (r.contains('network') || r.contains('timeout') ||
        r.contains('failed to fetch')) {
      return 'Network issue. Check your internet and try again.';
    }
    if (r.contains('access_denied') || r.contains('denied')) {
      return 'Google didn’t grant access. Please try again.';
    }
    if (r.contains('sign_in_failed') || r.contains('developer_error') ||
        r.contains('apiexception: 10')) {
      // Classic Android misconfiguration: SHA-1/256 not registered in
      // Firebase, or google-services.json is stale.
      return 'Google sign-in isn’t configured for this build yet. '
          '(App team: check SHA-1/256 + google-services.json.)';
    }
    return 'Couldn’t sign in with Google right now. Please try again.';
  }

  /// Kept as an alias — [pick] itself now always forces the chooser.
  Future<GoogleResult> pickDifferent() => pick();

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}

