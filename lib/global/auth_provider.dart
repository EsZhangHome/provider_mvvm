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
    ApiClient.instance.setTokenProvider(() => _token);
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
      return;
    }
    _token = await TokenStorage.getToken();
    final userJson = LocalStorage.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      _currentUser =
          UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  // 登录成功后保存 token 和用户信息，同时通知路由刷新登录状态。
  Future<void> loginSuccess(String token, UserModel user) async {
    _token = token;
    _currentUser = user;
    ApiClient.instance.resetUnauthorizedGuard();
    await TokenStorage.saveToken(token);
    await LocalStorage.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  // 退出登录时清空内存和本地缓存，GoRouter 会自动拦回登录页。
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await TokenStorage.clearToken();
    await LocalStorage.remove(_userKey);
    notifyListeners();
  }
}
