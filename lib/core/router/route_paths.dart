// lib/core/router/route_paths.dart
//
// 作用：集中管理所有路由路径常量，避免字符串散落在各页面和路由守卫中。
//
// 设计要点：
// 1. 所有路径使用 static const，编译时常量，零运行时开销
// 2. 私有构造函数防止实例化，这个类只作为常量容器
// 3. 路径命名采用小写+下划线风格，与 URL 规范一致
// 4. home 是 main 的别名，方便业务代码使用语义化的路径名
//
// 路由结构：
// /login            → 登录页
// /main             → 主框架页（包含底部 Tab）
// /main/home        → 主页 Tab（进入 MainPage 时默认选中首页）
// /main/community   → 社区 Tab
// /main/mine        → 我的 Tab

/// 路由路径集中管理。
///
/// 新增页面路由时，只需要在这里添加一个 static const 字段即可。
/// 不要在页面中直接写 '/login' 这种字符串。
class RoutePaths {
  const RoutePaths._();

  /// 登录页路径。
  /// 未登录用户会被重定向到这里。
  static const String login = '/login';

  /// 启动页路径。
  /// App 正在恢复本地登录态时停留在这里，避免登录页闪现。
  static const String splash = '/splash';

  /// 主框架页路径，登录后的根页面。
  /// MainPage 内部通过 IndexedStack 管理三个 Tab 页面。
  static const String main = '/main';

  /// 主页面的别名，指向 /main。
  /// 使用 home 比 main 更语义化，代码可读性更好。
  static const String home = main;

  /// 主页 Tab 路径：进入 MainPage 时默认选中首页（index=0）。
  static const String mainHome = '/main/home';

  /// 社区 Tab 路径：进入 MainPage 时选中社区（index=1）。
  static const String mainCommunity = '/main/community';

  /// 我的 Tab 路径：进入 MainPage 时选中我的（index=2）。
  static const String mainMine = '/main/mine';
}
