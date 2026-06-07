// lib/features/main/view_model/main_view_model.dart
import 'package:flutter/foundation.dart';

// MainViewModel 只管理底部 Tab 的下标，不放任何首页、社区、我的业务数据。
class MainViewModel extends ChangeNotifier {
  MainViewModel({int initialIndex = 0}) : _tabIndex = initialIndex;

  int _tabIndex;

  int get tabIndex => _tabIndex;

  void setTabIndex(int index) {
    if (index == _tabIndex) {
      return;
    }
    _tabIndex = index;
    notifyListeners();
  }
}
