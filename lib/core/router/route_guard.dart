// lib/core/router/route_guard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../global/auth_provider.dart';
import 'route_paths.dart';

abstract class RouteGuard {
  String? redirect(GoRouterState state, BuildContext context);
}

class AuthRouteGuard implements RouteGuard {
  AuthRouteGuard(this.authProvider);

  final AuthProvider authProvider;

  @override
  String? redirect(GoRouterState state, BuildContext context) {
    final isLoginRoute = state.matchedLocation == RoutePaths.login;
    final isProtectedRoute = state.matchedLocation == RoutePaths.main ||
        state.matchedLocation == RoutePaths.mainHome ||
        state.matchedLocation == RoutePaths.mainCommunity ||
        state.matchedLocation == RoutePaths.mainMine;

    if (!authProvider.isLoggedIn && isProtectedRoute) {
      return RoutePaths.login;
    }
    if (authProvider.isLoggedIn && isLoginRoute) {
      return RoutePaths.main;
    }
    return null;
  }
}
