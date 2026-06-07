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
    // 登录接口通常返回 token + user。
    // user 结构异常时用空 Map 兜底，交给 UserModel.fromJson 生成默认空字段。
    return LoginResponse(
      token: asOr(json['token'], ''),
      user: UserModel.fromJson(
        asOr<Map<String, dynamic>>(json['user'], <String, dynamic>{}),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    // 用于单元测试或状态比较。
    return identical(this, other) ||
        other is LoginResponse && other.token == token && other.user == user;
  }

  @override
  int get hashCode => Object.hash(token, user);
}
