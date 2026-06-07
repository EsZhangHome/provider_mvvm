// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/router/route_guard.dart';
import 'global/auth_provider.dart';
import 'global/theme_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider 是全局依赖入口，App 启动后这些对象会一直可用。
    // 这里仅放真正的全局状态：登录态和主题；页面级状态不要放到这里。
    return MultiProvider(
      providers: [
        // create 创建对象，Provider 会在合适时机负责监听和销毁。
        // AuthProvider 启动后会尝试从安全存储恢复 token，并驱动路由守卫判断登录状态。
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),

        // ThemeProvider 启动后读取本地主题设置，并缓存 ThemeData，避免重复创建主题对象。
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // GoRouter 必须保持稳定。
  // 如果每次 ThemeProvider 或 AuthProvider notify 后都创建新 GoRouter，
  // 可能导致页面栈丢失、重定向重复执行、页面状态重置。
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 路由只创建一次。AuthProvider 自己是 refreshListenable，登录状态变化不需要重建 router。
    final authProvider = context.read<AuthProvider>();
    _router ??= AppRouter(
      authProvider,
      // 路由守卫采用列表形式，后续可继续添加会员守卫、权限守卫、灰度守卫等。
      guards: [AuthRouteGuard(authProvider)],
    ).config;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // MaterialApp.router 接入 GoRouter，路由跳转和登录拦截都交给路由层。
        return MaterialApp.router(
          title: 'Provider MVVM',
          debugShowCheckedModeBanner: false,

          // 主题由 ThemeProvider 管理，页面只负责切换，不直接创建 ThemeData。
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,

          // GoRouter 负责所有页面声明、登录拦截和 404 兜底。
          routerConfig: _router!,

          // 当前先接入 Flutter 官方本地化代理，文案集中放在 AppStrings。
          // 后续如果改成 arb 文件，这里仍然是 MaterialApp 的国际化入口。
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
        );
      },
    );
  }
}
