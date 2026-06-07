// lib/features/mine/view_model/mine_view_model.dart
//
// 作用：我的页 ViewModel，负责"我的"Tab 的数据加载和状态管理。
//
// 架构职责：
// - 持有 user，暴露给页面展示（显示当前用户信息）
// - 提供 loadMine 方法，接收 AuthProvider 的 currentUser 作为参数
// - 继承 BaseViewModel，自动获得 loading/error/empty/success 状态管理
// - 当前直接使用 AuthProvider 的用户信息，后续接入真实接口时替换
//
// 与 AuthProvider 的关系：
// - MineViewModel 从 AuthProvider 获取 currentUser 作为初始数据
// - 后续如果"我的页"有独立接口，MineViewModel 会从接口获取更详细的数据
// - AuthProvider 仍然负责全局登录态管理

import '../../../core/base/base_view_model.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/models/user_model.dart';

/// 我的页 ViewModel。
///
/// 只维护"我的页"需要展示的数据，不管理全局登录态。
/// 全局登录态由 AuthProvider 管理。
class MineViewModel extends BaseViewModel {
  /// 我的页展示的用户信息
  UserModel? user;

  /// 加载"我的页"数据。
  ///
  /// [currentUser]：来自 AuthProvider 的当前登录用户信息。
  ///
  /// 处理流程：
  /// 1. 检查 currentUser 是否为空（未登录兜底）
  /// 2. 模拟异步加载（后续替换为真实接口调用）
  /// 3. 保存结果并通知 UI 刷新
  Future<void> loadMine(UserModel? currentUser) async {
    // ---- 步骤 1：防御式检查 ----
    // 未登录用户理论上会被路由守卫拦到登录页
    // 这里仍然做兜底，避免异常状态下页面空指针
    if (currentUser == null) {
      setError(AppStrings.userMissing);
      return;
    }

    // ---- 步骤 2：加载数据 ----
    final loadedUser = await asyncRequest<UserModel>(
      () async {
        // 当前没有独立"我的页"接口，先用当前登录用户模拟一次异步加载
        // 后续接真实接口时，把这里替换为 MineRepository.fetchMine
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return currentUser;
      },
    );

    // ---- 步骤 3：保存结果 ----
    if (loadedUser != null) {
      user = loadedUser;
      safeNotifyListeners();
    }
  }
}