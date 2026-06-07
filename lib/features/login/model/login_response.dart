// lib/features/login/model/login_response.dart
import '../../../shared/models/user_model.dart';
import '../../../core/utils/json_helper.dart';

// 登录响应结果：token 用来鉴权，user 用来展示用户信息。
class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.user,
  });

  final String token;
  final UserModel user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: asOr(json['token'], ''),
      user: UserModel.fromJson(
        asOr<Map<String, dynamic>>(json['user'], <String, dynamic>{}),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LoginResponse && other.token == token && other.user == user;
  }

  @override
  int get hashCode => Object.hash(token, user);
}
