// lib/features/login/model/login_request.dart
// 登录请求参数。ViewModel 组装它，Repository 再把它交给接口。
class LoginRequest {
  const LoginRequest({
    required this.account,
    required this.password,
  });

  final String account;
  final String password;

  Map<String, dynamic> toJson() {
    // 转成接口需要的 JSON 格式。
    return {
      'account': account,
      'password': password,
    };
  }
}
