// lib/features/login/view_model/login_view_model.dart
//
// 作用：登录页 ViewModel，负责登录表单校验和登录业务逻辑。
//
// 架构职责：
// - 持有 LoginRepository，通过它执行登录请求
// - 持有 token 和 user，登录成功后由 LoginPage 读取并传给 AuthProvider
// - 提供 login 方法，执行表单校验 + 登录请求
// - 返回 bool 表示登录是否成功，LoginPage 根据结果决定是否跳转
//
// 数据流：
// LoginPage._login() → LoginViewModel.login(account, password)
//   → 表单校验（空值检查）
//   → asyncRequest(() → repository.login(LoginRequest(account, password)))
//     → 自动 loading → success/error
//       → 成功：保存 token 和 user → 返回 true
//       → 失败：asyncRequest 自动设置 error 状态 → 返回 false
//   → LoginPage 读取 viewModel.token 和 viewModel.user
//   → 调用 AuthProvider.loginSuccess(token, user)
//   → GoRouter 跳转到主页面

import '../../../core/base/base_view_model.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/models/user_model.dart';
import '../model/login_request.dart';
import '../repository/login_repository.dart';

/// 登录页 ViewModel。
///
/// 登录页的状态和业务逻辑都放在这里，页面只负责收集输入和展示结果。
/// 这样页面代码更简洁，业务逻辑也更容易单元测试。
class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._repository);

  /// 登录数据仓库，通过 get_it 注入
  final LoginRepository _repository;

  /// 登录成功后后端返回的用户信息
  UserModel? user;

  /// 登录成功后后端返回的 token
  String? token;

  /// 判断当前 ViewModel 是否已经拿到登录态。
  bool get isLogin => token != null && token!.isNotEmpty;

  /// 执行登录操作。
  ///
  /// [account]：用户输入的账号（手机号或邮箱）
  /// [password]：用户输入的密码
  ///
  /// 返回值：true 表示登录成功，false 表示登录失败。
  ///
  /// 处理流程：
  /// 1. 表单校验：检查账号和密码是否为空
  /// 2. 调用 asyncRequest 执行登录请求（自动处理 loading/error 状态）
  /// 3. 请求成功：保存 token 和 user，返回 true
  /// 4. 请求失败：asyncRequest 自动设置 error 状态，返回 false
  Future<bool> login(String account, String password) async {
    // ---- 步骤 1：表单校验 ----
    if (account.trim().isEmpty || password.trim().isEmpty) {
      // 表单校验属于页面业务逻辑，放在 ViewModel 中更容易测试
      setError(AppStrings.enterAccountAndPassword);
      return false;
    }

    // ---- 步骤 2：执行登录请求 ----
    // asyncRequest 会自动处理 loading/error/success 状态切换
    final response = await asyncRequest(
      () => _repository.login(
        // 组装请求参数，去除首尾空格
        LoginRequest(account: account.trim(), password: password.trim()),
        cancelToken: cancelToken,
      ),
      cancelToken: cancelToken,
    );

    // ---- 步骤 3：处理结果 ----
    if (response == null) {
      // asyncRequest 返回 null 表示：
      // - 请求失败（error 状态已自动设置）
      // - 请求被防抖拦截
      // - 请求被取消
      return false;
    }

    // ---- 步骤 4：保存登录结果 ----
    // 只把页面需要的数据暴露为清晰字段
    // 页面不需要知道 LoginResponse 的完整结构
    token = response.token;
    user = response.user;
    return true;
  }
}