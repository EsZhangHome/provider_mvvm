// lib/app.dart
//
// 作用：App 的根 Widget，负责组装全局 Provider、主题、路由和国际化。
//
// 架构职责：
// - 通过 MultiProvider 注入全局状态（AuthProvider、ThemeProvider）
// - 通过 MaterialApp.router 接入 GoRouter，实现声明式路由
// - 主题由 ThemeProvider 管理，支持明暗切换
// - 国际化代理配置，当前使用 Flutter 内置本地化
//
// 组件层次：
// MyApp（StatelessWidget）
//   └── MultiProvider
//        ├── ChangeNotifierProvider<AuthProvider>
//        └── ChangeNotifierProvider<ThemeProvider>
//             └── _AppView（StatefulWidget）
//                  └── Consumer<ThemeProvider>
//                       └── MaterialApp.router
//                            ├── theme: ThemeProvider.lightTheme
//                            ├── darkTheme: ThemeProvider.darkTheme
//                            ├── themeMode: ThemeProvider.themeMode
//                            └── routerConfig: GoRouter
//
// 设计要点：
// 1. MyApp 是纯 StatelessWidget，不持有状态
// 2. _AppView 是 StatefulWidget，负责缓存 GoRouter 实例（只创建一次）
// 3. Consumer<ThemeProvider> 确保主题切换时 MaterialApp 能正确重建
// 4. GoRouter 不会因为 ThemeProvider 的 notifyListeners 而重建

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/router/route_guard.dart';
import 'global/auth_provider.dart';
import 'global/theme_provider.dart';

/// App 的根 Widget。
///
/// 职责：组装全局 Provider 和路由。
/// 不包含任何业务逻辑，业务逻辑在 features 中。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider 是全局依赖入口，App 启动后这些对象会一直可用
    // 这里仅放真正的全局状态（登录态和主题），页面级状态不要放到这里
    return MultiProvider(
      providers: [
        // AuthProvider：统一管理登录态（token、当前用户、登录/退出）
        // create 创建对象，Provider 会在合适时机负责监听和销毁
        // 启动后通过 restoreSession 从安全存储恢复 token，驱动路由守卫判断登录状态
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),

        // ThemeProvider：管理明暗主题，并把用户选择持久化到本地
        // 启动后读取本地主题设置，并缓存 ThemeData，避免重复创建主题对象
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
      ],
      child: const _AppView(),
    );
  }
}

/// 内部 StatefulWidget，负责持有 GoRouter 实例。
///
/// 为什么是 StatefulWidget：
/// - GoRouter 实例必须保持稳定，不能每次 build 都创建新的
/// - 如果每次 ThemeProvider 或 AuthProvider notify 后都创建新 GoRouter，
///   可能导致页面栈丢失、重定向重复执行、页面状态重置
/// - 使用 StatefulWidget 的 _router 字段缓存，确保只创建一次
class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  /// GoRouter 实例缓存。
  ///
  /// 使用 ??= 确保只创建一次。
  /// AuthProvider 作为 refreshListenable 注册到 GoRouter 内部，
  /// 所以登录状态变化时不需要重建 router，GoRouter 自己会重新执行 redirect。
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 路由只创建一次
    // AuthProvider 已经是 GoRouter 的 refreshListenable，
    // 登录状态变化时 GoRouter 会自动重新执行 redirect，不需要重建 router
    final authProvider = context.read<AuthProvider>();
    _router ??= AppRouter(
      authProvider,
      // 路由守卫采用列表形式，后续可继续添加：
      // - 会员守卫（VipRouteGuard）
      // - 权限守卫（PermissionRouteGuard）
      // - 灰度守卫（FeatureFlagRouteGuard）
      guards: [AuthRouteGuard(authProvider)],
    ).config;
  }

  @override
  Widget build(BuildContext context) {
    // Consumer<ThemeProvider> 确保主题切换时 MaterialApp 正确重建
    // 注意：GoRouter 不会因为 ThemeProvider 的 notifyListeners 而重建
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // MaterialApp.router 接入 GoRouter
        // 路由跳转和登录拦截都交给路由层处理
        return MaterialApp.router(
          title: 'Provider MVVM',
          // 隐藏 debug 模式下的 "Debug" 标签
          debugShowCheckedModeBanner: false,

          // 主题由 ThemeProvider 管理，页面只负责切换，不直接创建 ThemeData
          // ThemeData 在 ThemeProvider 中缓存，避免重复创建
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,

          // GoRouter 负责所有页面声明、登录拦截和 404 兜底
          routerConfig: _router!,

          // 国际化代理
          // 当前先接入 Flutter 官方本地化代理，文案集中放在 AppStrings
          // 后续如果改成 arb 文件，这里仍然是 MaterialApp 的国际化入口
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        );
      },
    );
  }
}
