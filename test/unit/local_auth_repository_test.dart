import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apna_ledger/core/config/env_config.dart';
import 'package:apna_ledger/core/config/flavor.dart';
import 'package:apna_ledger/core/error/failure.dart';
import 'package:apna_ledger/core/services/local_storage_service.dart';
import 'package:apna_ledger/features/auth/data/local_auth_repository.dart';

void main() {
  late LocalAuthRepository repo;

  setUp(() async {
    // verifyOtp reads EnvConfig.instance.masterOtp.
    EnvConfig.init(const EnvConfig(
      flavor: Flavor.qa,
      appName: 'test',
      enableCrashlytics: false,
      enableAnalytics: false,
      masterOtp: '123456',
    ));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = LocalAuthRepository(LocalStorageService(prefs));
  });

  test('register then login succeeds and persists a session', () async {
    await repo.register(phone: '9876543210', password: 'secret');

    expect(await repo.phoneExists('9876543210'), isTrue);

    final user = await repo.login(phone: '9876543210', password: 'secret');
    expect(user.phone, '9876543210');

    final restored = await repo.currentUser();
    expect(restored?.phone, '9876543210');
  });

  test('duplicate registration throws accountExists', () async {
    await repo.register(phone: '9111111111', password: 'secret');
    expect(
      () => repo.register(phone: '9111111111', password: 'again1'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('wrong password throws loginFailed', () async {
    await repo.register(phone: '9222222222', password: 'correct');
    expect(
      () => repo.login(phone: '9222222222', password: 'wrong0'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('logout clears the session', () async {
    await repo.register(phone: '9333333333', password: 'secret');
    await repo.logout();
    expect(await repo.currentUser(), isNull);
  });

  test('verifyOtp accepts the master OTP only', () {
    expect(repo.verifyOtp('123456'), isTrue);
    expect(repo.verifyOtp('000000'), isFalse);
  });

  test('resetPassword changes the credential', () async {
    await repo.register(phone: '9444444444', password: 'oldpass');
    await repo.resetPassword(phone: '9444444444', newPassword: 'newpass');
    final user = await repo.login(phone: '9444444444', password: 'newpass');
    expect(user.phone, '9444444444');
  });
}
