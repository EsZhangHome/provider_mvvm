// lib/features/home/view_model/home_view_model.dart
//
// 作用：首页 ViewModel，负责首页数据加载和状态管理。
//
// 架构职责：
// - 持有 HomeRepository，通过它获取首页数据
// - 持有 bannerList，暴露给页面展示
// - 提供 loadHome 方法，页面通过 onModelReady 调用
// - 继承 BaseViewModel，自动获得 loading/error/empty/success 状态管理
//
// 数据流：
// HomePage.onModelReady → HomeViewModel.loadHome()
//   → asyncRequest(() → repository.fetchBanners(cancelToken))
//     → 自动 loading → success/empty/error
//       → 更新 bannerList → safeNotifyListeners()
//         → BasePage 的 Consumer 收到通知 → StateView 切换 UI → 页面展示数据

import '../../../core/base/base_view_model.dart';
import '../model/home_banner.dart';
import '../repository/home_repository.dart';

/// 首页 ViewModel。
///
/// 负责请求首页数据，并把 bannerList 暴露给页面。
/// 页面不需要知道数据来自缓存还是网络，这些细节都封装在 Repository 中。
class HomeViewModel extends BaseViewModel {
  HomeViewModel(this._repository);

  /// 首页数据仓库，通过 get_it 注入
  final HomeRepository _repository;

  /// 首页 Banner 列表，页面直接读取这个字段展示
  List<HomeBanner> bannerList = [];

  /// 加载首页数据。
  ///
  /// 调用时机：页面 onModelReady 时调用。
  ///
  /// 处理流程：
  /// 1. 调用 asyncRequest 发起请求（自动处理 loading/error/success/empty）
  /// 2. 请求成功时，更新 bannerList 并通知 UI 刷新
  /// 3. 请求失败时，asyncRequest 内部会自动切换到 error 状态，页面展示 ErrorView
  Future<void> loadHome() async {
    // asyncRequest 自动处理：
    // - loading 状态切换（请求开始时）
    // - success/empty 状态切换（根据 isEmpty 判断）
    // - error 状态切换（捕获异常时）
    // - 请求防抖（同一时间只允许一个请求）
    // - CancelToken 管理（页面销毁时自动取消）
    final banners = await asyncRequest<List<HomeBanner>>(
      // 请求闭包：调用 Repository，透传 cancelToken
      () => _repository.fetchBanners(cancelToken: cancelToken),
      // 判断数据是否为空：列表长度为 0 时进入 empty 状态
      isEmpty: (data) => data.isEmpty,
      cancelToken: cancelToken,
    );

    // asyncRequest 返回 null 表示请求失败或被取消
    if (banners != null) {
      // 更新页面可见字段
      bannerList = banners;
      // 通知 UI 刷新（通过 safeNotifyListeners 确保 dispose 后不会刷新）
      safeNotifyListeners();
    }
  }
}
