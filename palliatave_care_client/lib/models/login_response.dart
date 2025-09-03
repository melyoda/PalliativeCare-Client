import 'package:palliatave_care_client/models/user_account.dart';

class LoginResponse {
  final String jwtToken;
  final UserAccount user;

  LoginResponse({required this.jwtToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      jwtToken: json['jwtToken'] as String,
      user: UserAccount.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}