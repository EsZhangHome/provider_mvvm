// lib/features/login/repository/login_repository.dart
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';

// 登录仓库接口。ViewModel 依赖接口，单元测试时可以传 FakeLoginRepository。
abstract class LoginRepository {
  Future<LoginResponse> login(
    LoginRequest request, {
    CancelToken? cancelToken,
  });
}

// 登录数据仓库实现。它只负责请求和转换数据，不关心页面怎么展示。
class LoginRepositoryImpl implements LoginRepository {
  LoginRepositoryImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiClient.instance;

  // 保留 ApiClient 依赖，真实后端接入时直接替换当前模拟数据分支。
  // ignore: unused_field
  final ApiService _apiService;

  @override
  Future<LoginResponse> login(
    LoginRequest request, {
    CancelToken? cancelToken,
  }) async {
    // 当前没有真实后端，先模拟接口；接入真实后端时改为下面注释里的 _apiClient.post。
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return LoginResponse.fromJson({
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '1',
        'name': request.account.contains('@') ? 'Flutter User' : 'Mobile User',
        'email': request.account.contains('@')
            ? request.account
            : 'user@example.com',
        'avatarUrl': null,
      },
    });

    // final response = await _apiService.post<LoginResponse>(
    //   Endpoints.login,
    //   data: request.toJson(),
    //   cancelToken: cancelToken,
    //   fromJson: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    // );
    // return response.data!;
  }
}
