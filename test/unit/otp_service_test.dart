import 'package:apna_ledger/core/constants/app_constants.dart';
import 'package:apna_ledger/core/services/local_storage_service.dart';
import 'package:apna_ledger/core/services/otp_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentGateway implements SmsGateway {
  String? lastCode;
  @override
  Future<void> send({required String phone, required String code}) async =>
      lastCode = code;
}

void main() {
  const phone = '9876543210';

  Future<(OtpService, _SilentGateway)> build({String? master}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gateway = _SilentGateway();
    return (
      OtpService(LocalStorageService(prefs), gateway, masterOtp: master),
      gateway,
    );
  }

  test('QA master OTP verifies after a code was sent', () async {
    final (otp, _) = await build(master: AppConstants.qaMasterOtp);
    await otp.sendOtp(phone);
    expect(otp.verifyOtp(phone, '908212'), isTrue);
  });

  test('master OTP still requires the normal send step', () async {
    final (otp, _) = await build(master: AppConstants.qaMasterOtp);
    expect(otp.verifyOtp(phone, '908212'), isFalse);
  });

  test('master OTP is rejected when not configured (UAT / prod)', () async {
    final (otp, _) = await build();
    await otp.sendOtp(phone);
    expect(otp.verifyOtp(phone, '908212'), isFalse);
  });

  test('the real code keeps working alongside the master', () async {
    final (otp, gateway) = await build(master: AppConstants.qaMasterOtp);
    await otp.sendOtp(phone);
    expect(otp.verifyOtp(phone, gateway.lastCode!), isTrue);
  });
}
