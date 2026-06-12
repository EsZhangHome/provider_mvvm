// lib/features/main/view_model/main_view_model.dart
//
// 作用：主页面 ViewModel，只管理底部 Tab 的下标。
//
// 架构职责：
// - 只管理 _tabIndex 一个状态（当前选中的 Tab 下标）
// - 不存放任何首页、社区、我的业务数据
// - 各个 Tab 页面有自己的独立 ViewModel
//
// 为什么 MainViewModel 不继承 BaseViewModel：
// - MainViewModel 只管理 Tab 切换，不涉及网络请求
// - 不需要 loading/error/empty 状态管理
// - 不需要 CancelToken 和请求防抖
// - 直接继承 ChangeNotifier 更轻量
//
// Tab 下标约定：
// 0 → 首页（HomePage）
// 1 → 社区（CommunityPage）
// 2 → 我的（MinePage）

import 'package:flutter/foundation.dart';

/// 主页面 ViewModel，只管理底部 Tab 下标。
///
/// 职责单一：只处理 Tab 切换逻辑，不碰任何业务数据。
/// 三个 Tab 的业务数据分别由 HomeViewModel、CommunityViewModel、MineViewModel 管理。
class MainViewModel extends ChangeNotifier {
  MainViewModel({int initialIndex = 0}) : _tabIndex = initialIndex;

  /// 当前选中的底部 Tab 下标：
  /// 0 = 首页，1 = 社区，2 = 我的
  int _tabIndex;

  /// 当前 Tab 下标，IndexedStack 根据这个值决定展示哪个子页面。
  int get tabIndex => _tabIndex;

  /// 设置 Tab 下标。
  ///
  /// [index]：新的 Tab 下标（0/1/2）
  ///
  /// 防重复通知：如果点击的是当前 Tab，不触发 notifyListeners，
  /// 避免无意义的 rebuild。
  void setTabIndex(int index) {
    if (index == _tabIndex) {
      // 点击当前 Tab 时不重复通知，避免无意义 rebuild
      return;
    }
    _tabIndex = index;
    notifyListeners();
  }
}
