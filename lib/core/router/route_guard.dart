// lib/core/router/route_guard.dart
//
// 作用：定义路由守卫机制，控制用户在不同登录状态下能访问哪些页面。
//
// 设计要点：
// 1. RouteGuard 是抽象接口，方便扩展不同类型的守卫（登录守卫、权限守卫、会员守卫等）
// 2. 守卫返回 null 表示放行，返回路径字符串表示需要重定向到该路径
// 3. 多个守卫按顺序执行，第一个返回非 null 的守卫决定重定向目标
// 4. AuthRouteGuard 是基础实现，处理登录/未登录状态的路由拦截
//
// 扩展方式：
// ```dart
// class VipRouteGuard implements RouteGuard {
//   @override
//   String? redirect(GoRouterState state, BuildContext context) {
//     if (state.matchedLocation == '/vip' && !user.isVip) {
//       return '/upgrade';  // 非会员跳转到升级页
//     }
//     return null;
//   }
// }
// ```

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../global/auth_provider.dart';
import 'route_paths.dart';

/// 路由守卫抽象接口。
///
/// 每个守卫实现一个特定的拦截规则。
/// 所有守卫在 AppRouter 的 redirect 中按顺序执行，
/// 第一个返回非 null 路径的守卫决定最终的重定向目标。
abstract class RouteGuard {
  /// 检查当前路由是否需要重定向。
  ///
  /// [state]：GoRouter 当前状态，包含 matchedLocation（当前匹配的路由路径）
  /// [context]：当前 BuildContext，可用于获取 Provider 等
  ///
  /// 返回值：
  /// - null：允许访问当前路由，不重定向
  /// - 路径字符串：需要重定向到该路径（如 '/login'、'/main'）
  String? redirect(GoRouterState state, BuildContext context);
}

/// 登录状态路由守卫。
///
/// 拦截规则：
/// 1. 未登录用户访问受保护页面 → 重定向到登录页
/// 2. 已登录用户访问登录页 → 重定向到主页面（避免重复登录）
/// 3. 其他情况 → 放行
///
/// 受保护页面包括：
/// - /main（主框架页）
/// - /main/home（首页 Tab）
/// - /main/community（社区 Tab）
/// - /main/mine（我的 Tab）
class AuthRouteGuard implements RouteGuard {
  AuthRouteGuard(this.authProvider);

  /// 全局登录状态提供者，通过 Provider 在 App 顶层注入。
  final AuthProvider authProvider;

  @override
  String? redirect(GoRouterState state, BuildContext context) {
    // ---- 判断当前目标路由 ----
    // 是否是登录页
    final isLoginRoute = state.matchedLocation == RoutePaths.login;
    // 是否是受保护页面（需要登录才能访问）
    final isProtectedRoute = state.matchedLocation == RoutePaths.main ||
        state.matchedLocation == RoutePaths.mainHome ||
        state.matchedLocation == RoutePaths.mainCommunity ||
        state.matchedLocation == RoutePaths.mainMine;

    // ---- 规则 1：未登录 → 不能访问受保护页面 ----
    if (!authProvider.isLoggedIn && isProtectedRoute) {
      // 重定向到登录页，让用户先登录
      return RoutePaths.login;
    }

    // ---- 规则 2：已登录 → 不需要停留在登录页 ----
    if (authProvider.isLoggedIn && isLoginRoute) {
      // 重定向到主页面，避免用户看到登录页
      return RoutePaths.main;
    }

    // ---- 规则 3：其他情况放行 ----
    return null;
  }
}