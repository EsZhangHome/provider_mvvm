// lib/global/theme_provider.dart
import 'package:flutter/material.dart';

import '../core/storage/local_storage.dart';
import '../core/theme/app_theme.dart';

// 管理明暗主题，并把用户选择保存到本地。
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  // ThemeData 创建有一定成本，且 AppTheme.light/dark 是固定配置。
  // 缓存后 getter 只返回对象引用，不会每次 build 都重新创建。
  late ThemeData _cachedLightTheme;
  late ThemeData _cachedDarkTheme;

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _cachedLightTheme;
  ThemeData get darkTheme => _cachedDarkTheme;

  // App 启动时读取用户上次选择的主题。
  void loadTheme() {
    // 主题对象只在启动时创建一次。
    _cachedLightTheme = AppTheme.light();
    _cachedDarkTheme = AppTheme.dark();

    // 本地没有保存过时默认 light。
    final savedMode = LocalStorage.getString(_themeKey);
    _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // 切换主题后立即保存，下次打开 App 仍然生效。
  Future<void> toggleTheme() async {
    // 只切换 ThemeMode，不重新创建 ThemeData。
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await LocalStorage.setString(
        _themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
