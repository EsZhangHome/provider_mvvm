// lib/core/router/app_router.dart
//
// 作用：创建和配置 GoRouter 实例，管理所有页面路由声明和路由守卫。
//
// 架构职责：
// - 声明所有页面的路由映射（路径 → 页面 Widget）
// - 配置路由守卫链，控制登录/未登录状态下的页面访问
// - 配置 404 兜底页面（NotFoundView）
// - 将 AuthProvider 设置为 refreshListenable，登录状态变化时自动重新执行守卫
//
// 设计要点：
// 1. GoRouter 实例只创建一次，存储在 _AppViewState 中，避免重复创建导致路由栈丢失
// 2. AuthProvider 作为 refreshListenable，登录/退出后 GoRouter 会自动重新执行 redirect
// 3. 守卫列表可扩展，后续可以添加会员守卫、权限守卫、灰度守卫等
// 4. /main/home、/main/community、/main/mine 三个路径都指向 MainPage，只是 initialIndex 不同
//
// 路由工作流程：
// 1. 用户访问某路径
// 2. GoRouter 匹配路由
// 3. 执行 redirect 回调（按顺序执行所有守卫）
// 4. 如果守卫返回路径 → 重定向到该路径
// 5. 如果所有守卫返回 null → 展示匹配的页面

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/login/view/login_page.dart';
import '../../features/main/view/main_page.dart';
import '../../global/auth_provider.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/not_found_view.dart';
import 'route_guard.dart';
import 'route_paths.dart';

/// App 路由管理器。
///
/// 每个 AppRouter 实例持有一个 GoRouter 实例。
/// 在 _AppViewState 中创建并保持引用，避免每次 rebuild 都创建新路由。
///
/// 使用方式：
/// ```dart
/// // 在 _AppViewState 中
/// final authProvider = context.read<AuthProvider>();
/// _router ??= AppRouter(authProvider, guards: [AuthRouteGuard(authProvider)]).config;
///
/// // 在 MaterialApp.router 中
/// routerConfig: _router,
/// ```
class AppRouter {
  /// 构造函数：创建 GoRouter 实例并保存到 config 字段。
  ///
  /// [authProvider]：全局登录状态提供者，作为 refreshListenable 和守卫参数
  /// [guards]：路由守卫列表，按顺序执行
  AppRouter(
    AuthProvider authProvider, {
    required List<RouteGuard> guards,
  }) : config = _create(authProvider, guards);

  /// GoRouter 实例，传递给 MaterialApp.router 的 routerConfig。
  /// 整个 App 生命周期内保持不变。
  final GoRouter config;

  /// 创建 GoRouter 实例的静态工厂方法。
  ///
  /// 返回的 GoRouter 配置了：
  /// - 初始路由：/main（登录后的主页面）
  /// - refreshListenable：AuthProvider，登录状态变化时自动重新执行 redirect
  /// - 404 错误页面：NotFoundView
  /// - redirect：按顺序执行所有路由守卫
  /// - routes：所有页面的路由声明
  static GoRouter _create(AuthProvider authProvider, List<RouteGuard> guards) {
    return GoRouter(
      // ---- 初始路由 ----
      // App 启动时默认进入主页面。
      // 如果未登录，AuthRouteGuard 会在 redirect 中重定向到登录页。
      initialLocation: RoutePaths.main,

      // ---- 刷新监听 ----
      // AuthProvider 是 ChangeNotifier，当登录/退出时 notifyListeners 会触发
      // GoRouter 自动重新执行 redirect，从而实现登录状态的实时路由拦截。
      refreshListenable: authProvider,

      // ---- 404 错误页面 ----
      // 当请求的路径无法匹配任何路由时，展示 NotFoundView。
      errorBuilder: (context, state) => const NotFoundView(),

      // ---- 路由守卫 ----
      // 在每次路由变化时执行，按顺序遍历所有守卫。
      // 第一个返回非 null 路径的守卫决定最终的路由目标。
      // 所有守卫都返回 null 时，正常展示匹配的页面。
      redirect: (BuildContext context, GoRouterState state) {
        for (final guard in guards) {
          final redirectPath = guard.redirect(state, context);
          if (redirectPath != null) {
            // 守卫返回了重定向路径，终止遍历，GoRouter 会跳转到该路径
            return redirectPath;
          }
        }
        // 所有守卫都放行，正常展示页面
        return null;
      },

      // ---- 路由声明 ----
      routes: [
        // 登录页
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginPage(),
        ),

        // 启动页：恢复本地登录态时显示，避免登录页或受保护页面闪现
        GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) => const Scaffold(body: LoadingView()),
        ),

        // 主框架页（默认选中首页 Tab）
        GoRoute(
          path: RoutePaths.main,
          builder: (context, state) => const MainPage(),
        ),

        // 以下三个路径用于外部直接打开某个 Tab（如推送通知跳转）
        // 它们都指向 MainPage，只是通过 initialIndex 指定默认选中的 Tab
        // 这样设计的好处：不需要为每个 Tab 创建独立路由，状态管理更简单

        // 首页 Tab：initialIndex = 0
        GoRoute(
          path: RoutePaths.mainHome,
          builder: (context, state) => const MainPage(initialIndex: 0),
        ),

        // 社区 Tab：initialIndex = 1
        GoRoute(
          path: RoutePaths.mainCommunity,
          builder: (context, state) => const MainPage(initialIndex: 1),
        ),

        // 我的 Tab：initialIndex = 2
        GoRoute(
          path: RoutePaths.mainMine,
          builder: (context, state) => const MainPage(initialIndex: 2),
        ),
      ],
    );
  }
}
