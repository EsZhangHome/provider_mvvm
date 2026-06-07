// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

// App 主题集中管理，保持页面代码干净。
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.indigo,
      useMaterial3: false,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      useMaterial3: false,
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    );
  }
}
