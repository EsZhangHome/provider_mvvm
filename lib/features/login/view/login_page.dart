// lib/features/login/view/login_page.dart
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

// 登录页面：只处理输入框、按钮点击和跳转，不直接调用 Dio。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController =
      TextEditingController(text: 'user@example.com');
  final TextEditingController _passwordController =
      TextEditingController(text: '123456');

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.login)),
      body: BasePage<LoginViewModel>(
        // LoginViewModel 通过 get_it 创建。
        // 这样 LoginPage 不需要知道 LoginRepositoryImpl 怎么构造。
        create: () => locator<LoginViewModel>(),

        // 登录页提交时不希望整个页面变成空白 loading，
        // 所以用 overlay：表单还在，只是在上面盖一层加载遮罩。
        loadingStyle: LoadingStyle.overlay,
        builder: (context, viewModel) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextField(
                  controller: _accountController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.account,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.password,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  // 请求进行中禁用按钮，配合 BaseViewModel 的请求防抖，避免重复登录请求。
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

  Future<void> _login(BuildContext context, LoginViewModel viewModel) async {
    // 先让 ViewModel 完成登录业务，再把登录结果交给全局 AuthProvider 保存。
    final success = await viewModel.login(
        _accountController.text, _passwordController.text);
    if (!mounted ||
        !success ||
        viewModel.token == null ||
        viewModel.user == null) {
      // mounted=false 表示页面已经销毁，不能再使用 context。
      // success=false 或 token/user 为空，说明登录失败或数据不完整，不跳转。
      return;
    }

    // AuthProvider 保存 token/user 后会 notifyListeners，
    // GoRouter 会重新执行登录守卫，整个 App 的登录态也会同步更新。
    await context
        .read<AuthProvider>()
        .loginSuccess(viewModel.token!, viewModel.user!);
    if (mounted) {
      // 登录成功进入主框架页，MainPage 内部再管理首页/社区/我的三个 Tab。
      context.go(RoutePaths.main);
    }
  }
}
