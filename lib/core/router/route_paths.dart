// lib/core/router/route_paths.dart
// 路由路径集中管理，避免页面里到处写 '/home' 这种字符串。
class RoutePaths {
  const RoutePaths._();

  static const String login = '/login';
  static const String main = '/main';
  static const String home = main;
  static const String mainHome = '/main/home';
  static const String mainCommunity = '/main/community';
  static const String mainMine = '/main/mine';
}
