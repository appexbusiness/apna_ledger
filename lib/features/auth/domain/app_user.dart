import 'package:equatable/equatable.dart';

/// The signed-in user. Optional profile fields per the requirements
/// (email, name, dob, state are optional at registration).
///
/// [emailVerified] is set true only when a matching Google account has proven
/// ownership of [email] (there is NO email OTP). Mobile is considered verified
/// because every account is created via mobile + OTP.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.phone,
    this.fullName,
    this.email,
    this.dob,
    this.state,
    this.emailVerified = false,
  });

  final String id;
  final String phone;
  final String? fullName;
  final String? email;
  final DateTime? dob;
  final String? state;
  final bool emailVerified;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : phone;

  AppUser copyWith({
    String? phone,
    String? fullName,
    String? email,
    DateTime? dob,
    String? state,
    bool? emailVerified,
  }) =>
      AppUser(
        id: id,
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        dob: dob ?? this.dob,
        state: state ?? this.state,
        emailVerified: emailVerified ?? this.emailVerified,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone': phone,
        'fullName': fullName,
        'email': email,
        'dob': dob?.toIso8601String(),
        'state': state,
        'emailVerified': emailVerified,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        phone: m['phone'] as String,
        fullName: m['fullName'] as String?,
        email: m['email'] as String?,
        dob: m['dob'] != null ? DateTime.tryParse(m['dob'] as String) : null,
        state: m['state'] as String?,
        emailVerified: (m['emailVerified'] as bool?) ?? false,
      );

  @override
  List<Object?> get props =>
      [id, phone, fullName, email, dob, state, emailVerified];
}
