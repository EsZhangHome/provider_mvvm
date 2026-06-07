// lib/features/main/view_model/main_view_model.dart
import 'package:flutter/foundation.dart';

// MainViewModel 只管理底部 Tab 的下标，不放任何首页、社区、我的业务数据。
class MainViewModel extends ChangeNotifier {
  MainViewModel({int initialIndex = 0}) : _tabIndex = initialIndex;

  // 当前选中的底部 Tab 下标：
  // 0 首页，1 社区，2 我的。
  int _tabIndex;

  int get tabIndex => _tabIndex;

  void setTabIndex(int index) {
    if (index == _tabIndex) {
      // 点击当前 Tab 时不重复通知，避免无意义 rebuild。
      return;
    }
    _tabIndex = index;
    notifyListeners();
  }
}
