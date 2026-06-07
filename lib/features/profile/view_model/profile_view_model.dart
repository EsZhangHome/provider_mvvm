// lib/features/profile/view_model/profile_view_model.dart
//
// 作用：个人中心 ViewModel，负责加载用户详细信息和维护页面状态。
//
// 架构职责：
// - 持有 ProfileRepository，通过它获取用户详细资料
// - 持有 user，暴露给页面展示
// - 提供 loadProfile 方法，接收 AuthProvider 的 currentUser 作为参数
// - 继承 BaseViewModel，自动获得 loading/error/empty/success 状态管理
//
// 与 MineViewModel 的区别：
// - MineViewModel：我的 Tab 页，功能较简单，当前直接使用 AuthProvider 数据
// - ProfileViewModel：独立的个人中心页面，有独立的 ProfileRepository，
//   后续可以从接口获取更详细的用户资料（如个人简介、等级、积分等）

import '../../../core/base/base_view_model.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/models/user_model.dart';
import '../repository/profile_repository.dart';

/// 个人中心 ViewModel。
///
/// 负责加载用户信息并维护页面状态。
/// 与 MineViewModel 不同，ProfileViewModel 有独立的 ProfileRepository，
/// 后续可以接入真实接口获取更详细的用户资料。
class ProfileViewModel extends BaseViewModel {
  ProfileViewModel(this._repository);

  /// 个人中心数据仓库，通过 get_it 注入
  final ProfileRepository _repository;

  /// 当前展示的用户信息
  UserModel? user;

  /// 加载个人中心数据。
  ///
  /// [currentUser]：来自 AuthProvider 的当前登录用户信息。
  /// 作为没有真实接口时的兜底数据。
  ///
  /// 处理流程：
  /// 1. 检查 currentUser 是否为空（未登录兜底）
  /// 2. 调用 Repository 获取用户详细资料
  /// 3. 保存结果并通知 UI 刷新
  Future<void> loadProfile(UserModel? currentUser) async {
    // ---- 步骤 1：防御式检查 ----
    // 未登录用户理论上无法访问受保护页面，但这里仍做防御式处理
    if (currentUser == null) {
      setError(AppStrings.userMissing);
      return;
    }

    // ---- 步骤 2：加载数据 ----
    final profile = await asyncRequest<UserModel>(
      // 调用 Repository，传入 AuthProvider 的用户信息作为兜底
      () => _repository.fetchProfile(currentUser, cancelToken: cancelToken),
      cancelToken: cancelToken,
    );

    // ---- 步骤 3：保存结果 ----
    if (profile != null) {
      user = profile;
      safeNotifyListeners();
    }
  }
}