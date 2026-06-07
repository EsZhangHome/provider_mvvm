// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/login/view/login_page.dart';
import '../../features/main/view/main_page.dart';
import '../../global/auth_provider.dart';
import '../../shared/widgets/not_found_view.dart';
import 'route_guard.dart';
import 'route_paths.dart';

// App 所有页面路由都放这里，页面跳转使用 RoutePaths 里的常量。
class AppRouter {
  AppRouter(
    AuthProvider authProvider, {
    required List<RouteGuard> guards,
  }) : config = _create(authProvider, guards);

  // 持有同一个 GoRouter 实例，避免 App rebuild 时重复创建路由对象。
  final GoRouter config;

  static GoRouter _create(AuthProvider authProvider, List<RouteGuard> guards) {
    return GoRouter(
      initialLocation: RoutePaths.main,
      // AuthProvider notifyListeners 后，GoRouter 会重新执行 redirect 判断登录状态。
      refreshListenable: authProvider,
      errorBuilder: (context, state) => const NotFoundView(),
      redirect: (BuildContext context, GoRouterState state) {
        for (final guard in guards) {
          final redirectPath = guard.redirect(state, context);
          if (redirectPath != null) {
            return redirectPath;
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RoutePaths.main,
          builder: (context, state) => const MainPage(),
        ),
        GoRoute(
          path: RoutePaths.mainHome,
          builder: (context, state) => const MainPage(initialIndex: 0),
        ),
        GoRoute(
          path: RoutePaths.mainCommunity,
          builder: (context, state) => const MainPage(initialIndex: 1),
        ),
        GoRoute(
          path: RoutePaths.mainMine,
          builder: (context, state) => const MainPage(initialIndex: 2),
        ),
      ],
    );
  }
}
