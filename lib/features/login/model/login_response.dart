// lib/features/login/model/login_response.dart
//
// 作用：登录响应结果模型，封装登录接口返回的 token 和用户信息。
//
// 设计要点：
// 1. token 用于后续所有请求的鉴权
// 2. user 用于展示用户信息（昵称、头像等）
// 3. 使用 json_helper 的安全类型转换，避免后端字段异常
// 4. user 字段解析异常时使用空 Map 兜底，UserModel.fromJson 会生成默认空字段
//
// 数据流：
// ApiService.post(Endpoints.login) → ApiResponse<LoginResponse>
//   → LoginResponse.fromJson(data) → LoginViewModel
//     → ViewModel 把 token 和 user 传给 AuthProvider.loginSuccess()

import '../../../shared/models/user_model.dart';
import '../../../core/utils/json_helper.dart';

/// 登录响应结果模型。
///
/// 包含登录成功后的 token（用于鉴权）和 user（用于展示用户信息）。
class LoginResponse {
  const LoginResponse({required this.token, required this.user});

  /// 鉴权令牌（JWT 等格式），后续所有请求通过 Authorization header 携带
  final String token;

  /// 登录用户信息
  final UserModel user;

  /// 从 JSON Map 创建 LoginResponse 实例。
  ///
  /// 参数说明：
  /// - token：必填字段，缺失时默认空字符串
  /// - user：必填字段，结构异常时用空 Map 兜底，
  ///   UserModel.fromJson 会生成所有字段为空的默认对象
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: asOr(json['token'], ''),
      user: UserModel.fromJson(
        // user 字段异常时传入空 Map，UserModel 内部会用默认值兜底
        asOr<Map<String, dynamic>>(json['user'], <String, dynamic>{}),
      ),
    );
  }

  /// 相等性比较：用于单元测试或状态比较。
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LoginResponse && other.token == token && other.user == user;
  }

  @override
  int get hashCode => Object.hash(token, user);
}
