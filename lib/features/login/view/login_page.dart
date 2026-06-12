// lib/features/login/view/login_page.dart
//
// 作用：登录页面，提供账号密码输入和登录按钮。
//
// 架构职责：
// - 管理输入框控制器（TextEditingController）
// - 通过 BasePage 创建 LoginViewModel 并管理 loading 状态
// - 使用 LoadingStyle.overlay（登录时保留表单，上面叠加遮罩）
// - 登录成功后从 ViewModel 取出 token/user，传给 AuthProvider 保存
// - 登录成功后通过 GoRouter 跳转到主页面
//
// 数据流：
// 用户输入账号密码 → 点击登录按钮 → _login()
//   → viewModel.login(account, password)
//     → 表单校验 → repository.login() → 返回 LoginResponse
//   → 成功：authProvider.loginSuccess(token, user) → context.go(RoutePaths.main)
//   → 失败：BasePage 自动展示 ErrorView（含 error message）

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_page.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../global/auth_provider.dart';
import '../view_model/login_view_model.dart';

/// 登录页面：只处理输入框、按钮点击和跳转，不直接调用 Dio。
///
/// 使用 StatefulWidget 而不是 StatelessWidget 的原因：
/// 需要管理 TextEditingController 的生命周期（创建和 dispose）。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// 账号输入框控制器
  final TextEditingController _accountController = TextEditingController(
    text: 'user@example.com',
  );

  /// 密码输入框控制器
  final TextEditingController _passwordController = TextEditingController(
    text: '123456',
  );

  @override
  void dispose() {
    // 释放输入框控制器，避免内存泄漏
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.login)),
      body: BasePage<LoginViewModel>(
        // 通过 get_it 创建 ViewModel
        create: () => locator<LoginViewModel>(),

        // 登录提交时使用 overlay 模式
        // 保留表单内容，在上面叠加半透明 loading 遮罩
        loadingStyle: LoadingStyle.overlay,

        builder: (context, viewModel) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 顶部留白，让表单居中
                const SizedBox(height: AppSpacing.xxxl),

                // App 名称
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 账号输入框：支持邮箱和手机号
                TextField(
                  controller: _accountController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.account,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 密码输入框：隐藏输入内容
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.password,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 登录按钮
                // 请求进行中时禁用按钮，配合 BaseViewModel 的请求防抖
                ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _login(context, viewModel),
                  child: const Text(AppStrings.login),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 执行登录流程。
  ///
  /// 流程：
  /// 1. 调用 ViewModel.login() 执行登录请求
  /// 2. 检查 mounted（页面是否已销毁）
  /// 3. 检查登录是否成功 + token/user 是否完整
  /// 4. 调用 AuthProvider.loginSuccess() 保存登录态
  /// 5. 通过 GoRouter 跳转到主页面
  Future<void> _login(BuildContext context, LoginViewModel viewModel) async {
    // ---- 步骤 1：执行登录 ----
    final success = await viewModel.login(
      _accountController.text,
      _passwordController.text,
    );

    // ---- 步骤 2：安全性检查 ----
    // mounted=false 表示页面已经销毁，不能再使用 context
    // success=false 或 token/user 为空，说明登录失败或数据不完整，不跳转
    final token = viewModel.token;
    final user = viewModel.user;
    if (!context.mounted || !success || token == null || user == null) {
      return;
    }

    // ---- 步骤 3：保存登录态 ----
    // AuthProvider 保存 token/user 后会 notifyListeners
    // GoRouter 作为 refreshListenable 会重新执行登录守卫
    await context.read<AuthProvider>().loginSuccess(token, user);

    // ---- 步骤 4：跳转到主页面 ----
    if (!context.mounted) {
      return;
    }

    // 登录成功进入主框架页，MainPage 内部再管理首页/社区/我的三个 Tab
    context.go(RoutePaths.main);
  }
}
