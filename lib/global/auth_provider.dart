// lib/global/auth_provider.dart
//
// 作用：全局登录状态管理器，统一管理 token、当前用户、登录/退出/恢复会话。
//
// 架构职责：
// - 持有当前 token 和用户信息，作为 App 全局登录态的唯一来源
// - 作为 ChangeNotifier，登录/退出时通知 GoRouter 和所有监听页面
// - 通过回调注入网络层（tokenProvider 和 onUnauthorized），解耦全局层和网络层
// - 管理本地持久化：token 存安全存储，用户信息存 SharedPreferences
//
// 数据流：
// 登录：LoginPage → LoginViewModel.login() → AuthProvider.loginSuccess()
//       → 保存 token/用户到本地 → notifyListeners() → GoRouter 重新执行守卫 → 跳到主页
//
// 退出：MinePage/ProfilePage → AuthProvider.logout()
//       → 清空 token/用户 → 清除本地存储 → notifyListeners() → GoRouter 跳到登录页
//
// 恢复：App 启动 → AuthProvider.restoreSession()
//       → 从安全存储读 token → 从 SharedPreferences 读用户 → notifyListeners()
//
// 401 处理：ApiClient 捕获 401 → UnauthorizedGuard → AuthProvider.logout()
//
// 设计要点：
// 1. AuthProvider 不直接依赖网络层，通过回调注入，方便测试
// 2. 登录成功时先更新内存再写入本地，保证 UI 响应速度
// 3. 退出登录时先清内存再清本地，保证 UI 立即响应
// 4. restoreSession 有防重复恢复保护（isLoggedIn 检查）

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/token_storage.dart';
import '../shared/models/user_model.dart';

/// 全局登录状态管理器。
///
/// 作为 ChangeNotifier 注入到 App 顶层，所有页面都可以通过 Provider 获取。
///
/// 使用方式：
/// ```dart
/// // 监听登录状态（页面会随登录/退出自动刷新）
/// final authProvider = context.watch<AuthProvider>();
///
/// // 读取登录状态（不监听）
/// final authProvider = context.read<AuthProvider>();
/// ```
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // ==================== 注入网络层回调 ====================

    // tokenProvider：每次请求前被 TokenInterceptor 调用
    // 返回内存中的 _token，确保请求使用的是最新 token
    ApiClient.instance.setTokenProvider(() => _token);

    // onUnauthorized：当 ApiClient 发现 401 时调用
    // 这样 token 过期后，全局登录态和路由守卫会一起刷新
    ApiClient.instance.setUnauthorizedCallback(logout);
  }

  // ==================== 常量 ====================

  /// 用户信息在 SharedPreferences 中的 key
  static const String _userKey = 'current_user';

  // ==================== 私有状态字段 ====================

  /// 当前 token，null 表示未登录。
  String? _token;

  /// 当前登录用户信息，null 表示未登录。
  UserModel? _currentUser;

  /// 是否正在从本地存储恢复登录态。
  bool _isRestoringSession = false;

  // ==================== 公开 getter ====================

  /// 当前 token（JWT 等格式的鉴权令牌）。
  String? get token => _token;

  /// 当前登录用户信息。
  UserModel? get currentUser => _currentUser;

  /// 是否正在从本地存储恢复登录态。
  bool get isRestoringSession => _isRestoringSession;

  /// 是否已登录。
  ///
  /// 判断标准：token 不为 null 且不为空字符串。
  /// 可以根据实际需求扩展（如检查 token 是否过期）。
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ==================== 会话恢复 ====================

  /// App 启动时从本地恢复登录态。
  ///
  /// 调用时机：App 启动时，Provider 创建 AuthProvider 后立即调用。
  ///
  /// 恢复流程：
  /// 1. 检查是否已在内存中登录（防重复恢复）
  /// 2. 从安全存储读取 token
  /// 3. 从 SharedPreferences 读取用户信息
  /// 4. 通知监听者（GoRouter 会重新执行路由守卫）
  Future<void> restoreSession() async {
    // 防重复恢复：如果内存中已经是登录状态，说明登录流程刚完成或已经恢复过
    // 避免异步恢复过程覆盖当前新登录的数据
    if (isLoggedIn) {
      return;
    }

    _isRestoringSession = true;

    try {
      // 从安全存储读取 token（异步操作）
      _token = await TokenStorage.getToken();

      // 用户基本信息不属于高敏感数据，放在 SharedPreferences 中便于快速恢复 UI
      final userJson = LocalStorage.getString(_userKey);
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
      }
    } finally {
      _isRestoringSession = false;
    }

    // 通知 GoRouter 和所有监听页面，让路由守卫根据恢复的登录状态重定向
    notifyListeners();
  }

  // ==================== 登录 ====================

  /// 登录成功后保存 token 和用户信息。
  ///
  /// 调用时机：LoginPage 在登录成功后调用。
  ///
  /// 处理流程：
  /// 1. 更新内存状态（token + user），让页面和路由守卫立即感知登录成功
  /// 2. 重置 401 守卫，允许新会话的下一次 401 触发退出
  /// 3. 写入本地存储（安全存储 + SharedPreferences），确保 App 重启后能恢复
  /// 4. notifyListeners，通知 GoRouter 重新执行路由守卫
  ///
  /// [token]：登录成功后后端返回的鉴权令牌
  /// [user]：登录成功后后端返回的用户信息
  Future<void> loginSuccess(String token, UserModel user) async {
    // ---- 步骤 1：更新内存状态 ----
    _token = token;
    _currentUser = user;

    // ---- 步骤 2：重置 401 守卫 ----
    // 新会话开始后，允许 401 守卫在下一次 token 失效时重新触发
    ApiClient.instance.resetUnauthorizedGuard();

    // ---- 步骤 3：写入本地存储 ----
    // token 存安全存储（系统级安全存储）
    await TokenStorage.saveToken(token);
    // 用户信息存 SharedPreferences（普通存储，快速恢复 UI）
    await LocalStorage.setString(_userKey, jsonEncode(user.toJson()));

    // ---- 步骤 4：通知所有监听者 ----
    // GoRouter（作为 refreshListenable）会重新执行 redirect
    // 已登录用户访问登录页会被重定向到主页面
    notifyListeners();
  }

  // ==================== 退出登录 ====================

  /// 退出登录，清空内存和本地缓存。
  ///
  /// 调用时机：MinePage、ProfilePage 的退出按钮点击，以及 401 回调。
  ///
  /// 处理流程：
  /// 1. 清空内存状态（token + user），保证页面立即响应退出状态
  /// 2. 清除本地存储（安全存储 + SharedPreferences），防止下次启动恢复旧登录态
  /// 3. notifyListeners，通知 GoRouter 重新执行路由守卫（会重定向到登录页）
  Future<void> logout() async {
    // ---- 步骤 1：清空内存状态 ----
    // 先清内存，让页面能马上响应退出状态
    _token = null;
    _currentUser = null;

    // ---- 步骤 2：清除本地存储 ----
    // 清除 token 和用户信息，避免下次启动又恢复旧登录态
    await TokenStorage.clearToken();
    await LocalStorage.remove(_userKey);

    // ---- 步骤 3：通知所有监听者 ----
    // GoRouter 会重新执行 redirect，未登录用户会被重定向到登录页
    notifyListeners();
  }
}
