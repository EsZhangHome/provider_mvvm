// lib/features/login/model/login_request.dart
//
// 作用：登录请求参数模型，封装登录接口需要的请求体字段。
//
// 设计要点：
// 1. 使用 const 构造函数，所有字段都是 final
// 2. 提供 toJson 方法，将请求参数转为 JSON Map
// 3. ViewModel 组装 LoginRequest，Repository 把它传给 ApiService
//
// 数据流：
// LoginPage → LoginViewModel.login(account, password)
//   → 组装 LoginRequest(account, password)
//   → LoginRepository.login(request)
//   → ApiService.post(data: request.toJson())

/// 登录请求参数模型。
///
/// 封装登录接口需要的账号和密码。
/// 后续可以扩展字段（如验证码、设备信息等）。
class LoginRequest {
  const LoginRequest({
    required this.account,
    required this.password,
  });

  /// 账号：手机号或邮箱
  final String account;

  /// 密码
  final String password;

  /// 序列化为 JSON Map，用于 POST 请求体。
  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'password': password,
    };
  }
}