import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injector.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/local_storage_service.dart';

final biometricServiceProvider = Provider((ref) => BiometricService());

/// Whether the device supports any local auth.
final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricServiceProvider).isAvailable(),
);

const _kAppLock = 'app_lock_enabled';
const _kPinHash = 'app_pin_hash';

String _hashPin(String pin) =>
    sha256.convert(utf8.encode('apnaledger::pin::$pin')).toString();

/// User preference: require biometric/device unlock on open.
final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier(ref.watch(localStorageProvider));
});

class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier(this._storage) : super(_storage.getBool(_kAppLock));
  final LocalStorageService _storage;

  Future<void> set(bool value) async {
    state = value;
    await _storage.setBool(_kAppLock, value);
  }
}

/// Whether a 4-digit PIN is set.
final pinProvider = StateNotifierProvider<PinNotifier, bool>((ref) {
  return PinNotifier(ref.watch(localStorageProvider));
});

class PinNotifier extends StateNotifier<bool> {
  PinNotifier(this._storage)
      : super((_storage.getString(_kPinHash) ?? '').isNotEmpty);
  final LocalStorageService _storage;

  Future<void> setPin(String pin) async {
    await _storage.setString(_kPinHash, _hashPin(pin));
    state = true;
  }

  Future<void> clear() async {
    await _storage.remove(_kPinHash);
    state = false;
  }

  bool verify(String pin) =>
      (_storage.getString(_kPinHash) ?? '') == _hashPin(pin);
}
