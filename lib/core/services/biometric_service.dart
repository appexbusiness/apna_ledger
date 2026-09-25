import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Outcome of a biometric availability check or auth attempt. Replaces the
/// old bool-only API, which silently swallowed every PlatformException —
/// that's why toggling "App Lock" used to do nothing with no error shown.
enum BiometricStatus {
  /// Authenticated successfully.
  success,

  /// Device has no lock screen / biometrics set up at all.
  notEnrolled,

  /// Hardware/OS doesn't support it (or a security patch is required).
  notAvailable,

  /// Native permission missing (Android USE_BIOMETRIC, or the app isn't
  /// wired up correctly — see FIREBASE_AND_BUILD_SETUP.md).
  permissionDenied,

  /// Too many failed attempts — device has temporarily/permanently locked
  /// biometric auth.
  lockedOut,

  /// User cancelled the prompt or backgrounded the app.
  cancelled,

  /// Anything else (logged with its raw message for debugging).
  other,
}

class BiometricResult {
  const BiometricResult(this.status, {this.message});
  final BiometricStatus status;
  final String? message;
  bool get ok => status == BiometricStatus.success;
}

/// Thin wrapper around device biometrics (Face ID / fingerprint / device PIN)
/// that surfaces real errors instead of hiding them.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device can do any local auth (biometric or device
  /// credential) — used to decide whether to offer the "App Lock" toggle
  /// at all. Does NOT throw; returns false with no crash if the platform
  /// call itself fails (e.g. missing native config).
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> enrolled() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Prompts the user. Allows device PIN/pattern fallback so it works even
  /// without a fingerprint/face enrolled. Unlike the old version, real
  /// platform errors are classified and returned instead of discarded.
  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok
          ? const BiometricResult(BiometricStatus.success)
          : const BiometricResult(BiometricStatus.cancelled);
    } on Exception catch (e) {
      final code = _codeOf(e);
      switch (code) {
        case auth_error.notAvailable:
          return BiometricResult(BiometricStatus.notAvailable, message: '$e');
        case auth_error.notEnrolled:
          return BiometricResult(BiometricStatus.notEnrolled, message: '$e');
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricResult(BiometricStatus.lockedOut, message: '$e');
        case auth_error.passcodeNotSet:
          return BiometricResult(BiometricStatus.notEnrolled, message: '$e');
        default:
          // Missing USE_BIOMETRIC permission / activity misconfiguration on
          // Android surfaces here too (e.g. "no_fragment_activity").
          final msg = '$e'.toLowerCase();
          if (msg.contains('permission') ||
              msg.contains('fragmentactivity') ||
              msg.contains('no_activity')) {
            return BiometricResult(BiometricStatus.permissionDenied,
                message: '$e');
          }
          return BiometricResult(BiometricStatus.other, message: '$e');
      }
    }
  }

  String? _codeOf(Exception e) {
    // PlatformException (from package:flutter/services.dart) has a `.code`
    // field; avoid a hard dependency here by reading it dynamically.
    try {
      return (e as dynamic).code as String?;
    } catch (_) {
      return null;
    }
  }
}
