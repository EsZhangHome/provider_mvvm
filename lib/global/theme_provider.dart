// lib/global/theme_provider.dart
//
// 作用：全局主题管理器，管理明暗主题切换，并把用户选择持久化到本地。
//
// 架构职责：
// - 持有当前 ThemeMode（light/dark）
// - 缓存 ThemeData 对象（避免每次 build 都重新创建）
// - 提供 toggleTheme 方法切换主题并持久化
// - 作为 ChangeNotifier，主题切换时通知 MaterialApp 重建
//
// 数据流：
// 切换主题：用户点击主题切换按钮 → ThemeProvider.toggleTheme()
//          → 更新 ThemeMode → 保存到 SharedPreferences → notifyListeners()
//          → Consumer<ThemeProvider> 重建 → MaterialApp 主题切换
//
// 恢复主题：App 启动 → ThemeProvider.loadTheme()
//          → 创建 ThemeData 缓存 → 读取本地保存的主题模式 → notifyListeners()
//
// 设计要点：
// 1. ThemeData 创建有成本，所以缓存后只返回引用，不重复创建
// 2. 主题切换后立即保存到本地，下次打开 App 仍然生效
// 3. ThemeMode 只是枚举切换，不触发热重载或其他副作用

import 'package:flutter/material.dart';

import '../core/storage/local_storage.dart';
import '../core/theme/app_theme.dart';

/// 全局主题管理器。
///
/// 作为 ChangeNotifier 注入到 App 顶层，通过 `Consumer<ThemeProvider>` 监听主题变化。
///
/// 使用方式：
/// ```dart
/// // 切换主题
/// context.read<ThemeProvider>().toggleTheme();
///
/// // 获取当前主题模式
/// final themeMode = context.watch<ThemeProvider>().themeMode;
/// ```
class ThemeProvider extends ChangeNotifier {
  /// 主题模式在 SharedPreferences 中的 key
  static const String _themeKey = 'theme_mode';

  // ==================== 私有状态 ====================

  /// 当前主题模式，默认 light。
  ThemeMode _themeMode = ThemeMode.light;

  // ==================== 缓存字段 ====================

  /// 浅色主题缓存。
  ///
  /// ThemeData 创建有一定成本（涉及颜色计算、组件样式合并等），
  /// 且 AppTheme.light() 返回的是固定配置，所以缓存后只返回引用。
  late ThemeData _cachedLightTheme;

  /// 深色主题缓存。
  late ThemeData _cachedDarkTheme;

  // ==================== 公开 getter ====================

  /// 当前主题模式。
  ThemeMode get themeMode => _themeMode;

  /// 缓存的浅色主题，避免每次 build 都重新创建。
  ThemeData get lightTheme => _cachedLightTheme;

  /// 缓存的深色主题。
  ThemeData get darkTheme => _cachedDarkTheme;

  // ==================== 初始化 ====================

  /// App 启动时加载主题配置。
  ///
  /// 调用时机：App 启动时，Provider 创建 ThemeProvider 后立即调用。
  ///
  /// 加载流程：
  /// 1. 创建 ThemeData 缓存（只创建一次，后续只返回引用）
  /// 2. 从 SharedPreferences 读取用户上次选择的主题模式
  /// 3. 通知监听者（MaterialApp 会使用最新的主题）
  void loadTheme() {
    // ---- 步骤 1：创建 ThemeData 缓存 ----
    // 主题对象只在启动时创建一次，后续切换只改 ThemeMode
    _cachedLightTheme = AppTheme.light();
    _cachedDarkTheme = AppTheme.dark();

    // ---- 步骤 2：读取本地保存的主题模式 ----
    // 本地没有保存过时默认 light
    final savedMode = LocalStorage.getString(_themeKey);
    _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;

    // ---- 步骤 3：通知 MaterialApp 重建 ----
    notifyListeners();
  }

  // ==================== 主题切换 ====================

  /// 切换明暗主题并保存到本地。
  ///
  /// 调用时机：用户点击主题切换按钮。
  ///
  /// 切换流程：
  /// 1. 切换 ThemeMode（light ↔ dark）
  /// 2. 保存到 SharedPreferences（下次打开 App 仍然生效）
  /// 3. notifyListeners（MaterialApp 会使用新主题重建）
  Future<void> toggleTheme() async {
    // ---- 步骤 1：切换 ThemeMode ----
    // 只切换 ThemeMode，不重新创建 ThemeData（缓存中的对象不变）
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    // ---- 步骤 2：保存到本地 ----
    // 下次打开 App 时，loadTheme 会读取这个值恢复主题
    await LocalStorage.setString(
      _themeKey,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );

    // ---- 步骤 3：通知 MaterialApp 重建 ----
    notifyListeners();
  }
}
