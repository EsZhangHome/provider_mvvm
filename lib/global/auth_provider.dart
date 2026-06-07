// lib/global/auth_provider.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/token_storage.dart';
import '../shared/models/user_model.dart';

// 统一管理登录态：token、当前用户、恢复登录、退出登录。
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // 网络层不直接依赖 AuthProvider，通过回调拿 token 和处理 401。
    // tokenProvider 每次请求前都会被 TokenInterceptor 调用，所以这里返回内存里的 _token。
    ApiClient.instance.setTokenProvider(() => _token);

    // 当 ApiClient 发现 401 时，会调用 logout。
    // 这样 token 过期后，全局登录态和路由守卫会一起刷新。
    ApiClient.instance.setUnauthorizedCallback(logout);
  }

  static const String _userKey = 'current_user';

  String? _token;
  UserModel? _currentUser;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // App 启动时从本地恢复登录态，用户不用每次打开都重新登录。
  Future<void> restoreSession() async {
    if (isLoggedIn) {
      // 如果内存中已经是登录状态，说明登录流程刚完成或已经恢复过。
      // 避免异步恢复过程覆盖当前新登录的数据。
      return;
    }

    // token 存在系统安全存储中，所以读取是异步的。
    _token = await TokenStorage.getToken();

    // 用户基本信息不属于高敏感数据，这里仍然放 LocalStorage，便于快速恢复 UI。
    final userJson = LocalStorage.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      _currentUser =
          UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  // 登录成功后保存 token 和用户信息，同时通知路由刷新登录状态。
  Future<void> loginSuccess(String token, UserModel user) async {
    // 先更新内存状态，让当前页面和路由守卫可以立即感知登录成功。
    _token = token;
    _currentUser = user;

    // 新会话开始后，允许 401 守卫在下一次 token 失效时重新触发。
    ApiClient.instance.resetUnauthorizedGuard();

    // 再写入本地存储，保证下次打开 App 可以恢复登录态。
    await TokenStorage.saveToken(token);
    await LocalStorage.setString(_userKey, jsonEncode(user.toJson()));

    // 通知 GoRouter refreshListenable 重新执行 redirect。
    notifyListeners();
  }

  // 退出登录时清空内存和本地缓存，GoRouter 会自动拦回登录页。
  Future<void> logout() async {
    // 先清内存，页面能马上响应退出状态。
    _token = null;
    _currentUser = null;

    // 再清本地缓存，避免下次启动又恢复旧登录态。
    await TokenStorage.clearToken();
    await LocalStorage.remove(_userKey);
    notifyListeners();
  }
}
