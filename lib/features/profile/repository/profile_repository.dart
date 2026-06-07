// lib/features/profile/repository/profile_repository.dart
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/models/user_model.dart';

// 个人中心仓库接口。ViewModel 依赖接口，测试时可以替换数据来源。
abstract class ProfileRepository {
  Future<UserModel> fetchProfile(
    UserModel fallbackUser, {
    CancelToken? cancelToken,
  });
}

// 个人中心数据仓库实现。当前直接返回登录时保存的用户信息。
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiClient.instance;

  // 保留 ApiClient 依赖，真实后端接入时直接替换当前模拟数据分支。
  // ignore: unused_field
  final ApiService _apiService;

  @override
  Future<UserModel> fetchProfile(
    UserModel fallbackUser, {
    CancelToken? cancelToken,
  }) async {
    // 当前没有真实后端，先模拟接口；接入真实后端时改为下面注释里的 _apiClient.get。
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return fallbackUser;

    // final response = await _apiService.get<UserModel>(
    //   Endpoints.profile,
    //   cancelToken: cancelToken,
    //   fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    // );
    // return response.data!;
  }
}
