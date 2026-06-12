// lib/core/theme/app_theme.dart
//
// 作用：集中管理 App 的明暗主题配置，避免 MaterialApp 中直接写 ThemeData。
//
// 设计要点：
// 1. 构造函数私有化，只通过静态方法 light() 和 dark() 获取主题
// 2. ThemeData 在 ThemeProvider 中缓存，避免每次 build 都重新创建
// 3. 主题配置集中管理，方便统一调整颜色、字体、间距等
// 4. 组件样式（如 AppBarTheme、CardTheme）也可以在这里统一配置
//
// 扩展方式：
// - 新增自定义颜色：添加 static const Color xxx = Color(0xFF...)
// - 新增组件主题：在 ThemeData 中添加 cardTheme、inputDecorationTheme 等
// - 支持更多主题变体：添加 static ThemeData highContrast() 等方法

import 'package:flutter/material.dart';

/// App 主题管理类。
///
/// 所有主题相关的配置集中在这里，而不是散落在 MaterialApp 和各个页面中。
/// ThemeProvider 在启动时调用 light() 和 dark() 创建 ThemeData 并缓存。
class AppTheme {
  const AppTheme._();

  /// 浅色主题。
  ///
  /// 配置项说明：
  /// - brightness: light → 浅色模式
  /// - primarySwatch: indigo → 主色调为靛蓝色
  /// - useMaterial3: false → 使用 Material 2 风格（Material 3 在某些组件上仍有兼容问题）
  /// - scaffoldBackgroundColor: #F7F8FA → 浅灰背景，比纯白色更柔和
  /// - appBarTheme: 无阴影、标题居中
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      // 主色调：影响 AppBar、FloatingActionButton、开关等组件的默认颜色
      primarySwatch: Colors.indigo,
      // 使用 Material 2 风格，兼容性更好
      useMaterial3: false,
      // 页面背景色：浅灰比纯白更柔和，适合长时间阅读
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      // AppBar 样式：无阴影（扁平化设计）、标题居中
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    );
  }

  /// 深色主题。
  ///
  /// 配置项说明：
  /// - brightness: dark → 深色模式
  /// - primarySwatch: 与浅色主题保持一致
  /// - 其他 Material 组件使用深色主题的默认暗色配色
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      useMaterial3: false,
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    );
  }
}
