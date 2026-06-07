// lib/features/login/repository/login_repository.dart
//
// 作用：登录数据仓库，负责执行登录请求并返回登录结果。
//
// 架构职责：
// - 定义 LoginRepository 接口（ViewModel 依赖接口，方便测试）
// - 实现 LoginRepositoryImpl（当前使用模拟数据，接入真实后端时替换）
// - 只负责请求和转换数据，不关心页面状态和跳转逻辑
//
// 接入真实后端的方式：
// 取消 login 方法中的模拟数据代码，启用下面注释中的 _apiService.post 调用。
// 只需要修改这个方法，ViewModel 和 Page 不需要任何改动。

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';

/// 登录仓库接口。
///
/// ViewModel 依赖这个接口，单元测试时可以传入 FakeLoginRepository。
abstract class LoginRepository {
  /// 执行登录请求。
  ///
  /// [request]：登录请求参数（账号 + 密码）
  /// [cancelToken]：取消令牌，页面销毁时取消请求
  ///
  /// 返回 LoginResponse（包含 token 和用户信息）。
  Future<LoginResponse> login(
    LoginRequest request, {
    CancelToken? cancelToken,
  });
}

/// 登录数据仓库实现。
///
/// 只负责请求和转换数据，不关心页面状态和跳转逻辑。
/// 这些由 ViewModel 和 Page 分别处理。
class LoginRepositoryImpl implements LoginRepository {
  LoginRepositoryImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiClient.instance;

  /// 网络服务（当前通过 DI 注入，真实后端接入时使用）
  // ignore: unused_field
  final ApiService _apiService;

  @override
  Future<LoginResponse> login(
    LoginRequest request, {
    CancelToken? cancelToken,
  }) async {
    // ---- 模拟网络请求耗时 ----
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // ---- 模拟登录成功响应 ----
    // 根据账号格式生成不同的用户名，模拟真实场景
    return LoginResponse.fromJson({
      // 用时间戳生成唯一 token，模拟真实 token
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '1',
        // 邮箱登录 → 'Flutter User'，手机号登录 → 'Mobile User'
        'name': request.account.contains('@') ? 'Flutter User' : 'Mobile User',
        'email': request.account.contains('@')
            ? request.account
            : 'user@example.com',
        'avatarUrl': null,
      },
    });

    // ---- 真实后端接入代码（取消注释即可使用） ----
    // final response = await _apiService.post<LoginResponse>(
    //   Endpoints.login,
    //   data: request.toJson(),
    //   cancelToken: cancelToken,
    //   fromJson: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    // );
    // return response.data!;
  }
}