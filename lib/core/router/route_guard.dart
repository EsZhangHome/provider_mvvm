// lib/core/router/route_guard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../global/auth_provider.dart';
import 'route_paths.dart';

abstract class RouteGuard {
  // 返回 null 表示允许继续访问当前路由。
  // 返回路径字符串表示需要重定向到该路径。
  String? redirect(GoRouterState state, BuildContext context);
}

class AuthRouteGuard implements RouteGuard {
  AuthRouteGuard(this.authProvider);

  final AuthProvider authProvider;

  @override
  String? redirect(GoRouterState state, BuildContext context) {
    // 当前目标是否是登录页。
    final isLoginRoute = state.matchedLocation == RoutePaths.login;

    // 这些页面需要登录后才能访问。
    final isProtectedRoute = state.matchedLocation == RoutePaths.main ||
        state.matchedLocation == RoutePaths.mainHome ||
        state.matchedLocation == RoutePaths.mainCommunity ||
        state.matchedLocation == RoutePaths.mainMine;

    if (!authProvider.isLoggedIn && isProtectedRoute) {
      // 未登录访问受保护页面，统一去登录页。
      return RoutePaths.login;
    }
    if (authProvider.isLoggedIn && isLoginRoute) {
      // 已登录用户不应该再停留在登录页，直接回主页面。
      return RoutePaths.main;
    }
    return null;
  }
}
