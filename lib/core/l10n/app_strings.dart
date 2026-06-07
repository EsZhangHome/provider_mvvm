// lib/core/l10n/app_strings.dart

// 当前先用静态常量集中管理文案，后续接 arb 时页面代码改动会更小。
class AppStrings {
  const AppStrings._();

  static const String appName = 'Provider MVVM';
  static const String home = '首页';
  static const String community = '社区';
  static const String mine = '我的';
  static const String profile = '个人中心';
  static const String login = '登录';
  static const String logout = '退出登录';
  static const String noData = '暂无数据';
  static const String retry = '重试';
  static const String pageNotFound = '页面不存在';
  static const String backHome = '返回首页';
  static const String account = '手机号/邮箱';
  static const String password = '密码';
  static const String enterAccountAndPassword = '请输入账号和密码';
  static const String requestTimeout = '请求超时，请稍后重试';
  static const String requestCanceled = '请求已取消';
  static const String networkError = '网络连接异常';
  static const String certificateError = '证书校验失败';
  static const String unknownError = '未知错误，请稍后重试';
  static const String serverError = '服务器异常，请稍后重试';
  static const String requestFailed = '请求失败，请稍后重试';
  static const String userMissing = '用户信息不存在，请重新登录';
  static const String switchTheme = '切换主题';
  static const String mockBannerTips = '模拟接口数据，可替换为真实 Banner 图片和跳转';
  static const String communityMockTips = '模拟社区内容，后续可接真实社区接口';
}
