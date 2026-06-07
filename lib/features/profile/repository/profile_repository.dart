// lib/features/profile/repository/profile_repository.dart
//
// 作用：个人中心数据仓库，负责获取用户详细资料。
//
// 架构职责：
// - 定义 ProfileRepository 接口（ViewModel 依赖接口，方便测试）
// - 实现 ProfileRepositoryImpl（当前使用模拟数据，接入真实后端时替换）
// - fallbackUser 参数：当没有真实接口时，使用 AuthProvider 的用户信息作为兜底
//
// 接入真实后端的方式：
// 取消 fetchProfile 方法中的模拟数据代码，启用下面注释中的 _apiService.get 调用。
// 只需要修改这个方法，ViewModel 和 Page 不需要任何改动。

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/models/user_model.dart';

/// 个人中心仓库接口。
///
/// ViewModel 依赖接口，测试时可以替换数据来源。
abstract class ProfileRepository {
  /// 获取用户个人资料。
  ///
  /// [fallbackUser]：来自 AuthProvider 的用户信息，在没有真实接口时作为兜底。
  /// [cancelToken]：取消令牌，页面销毁时取消请求。
  ///
  /// 返回用户详细信息。
  Future<UserModel> fetchProfile(
    UserModel fallbackUser, {
    CancelToken? cancelToken,
  });
}

/// 个人中心数据仓库实现。
///
/// 当前直接返回登录时保存的用户信息（fallbackUser）。
/// 接入真实接口后，从 _apiService 获取用户详细资料。
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiClient.instance;

  /// 网络服务（当前通过 DI 注入，真实后端接入时使用）
  // ignore: unused_field
  final ApiService _apiService;

  @override
  Future<UserModel> fetchProfile(
    UserModel fallbackUser, {
    CancelToken? cancelToken,
  }) async {
    // ---- 模拟网络请求耗时 ----
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // ---- 当前直接返回兜底用户信息 ----
    // fallbackUser 是 AuthProvider 里已有的用户信息
    return fallbackUser;

    // ---- 真实后端接入代码（取消注释即可使用） ----
    // final response = await _apiService.get<UserModel>(
    //   Endpoints.profile,
    //   cancelToken: cancelToken,
    //   fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    // );
    // return response.data!;
  }
}