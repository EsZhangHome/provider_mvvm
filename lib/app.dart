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
    return MultiProvider(
      providers: [
        // create 创建对象，Provider 会在合适时机负责监听和销毁。
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),
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
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 路由只创建一次。AuthProvider 自己是 refreshListenable，登录状态变化不需要重建 router。
    final authProvider = context.read<AuthProvider>();
    _router ??= AppRouter(
      authProvider,
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
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router!,
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
