// lib/features/mine/view/mine_page.dart
//
// 作用：我的 Tab 页面，展示用户信息和退出登录入口。
//
// 架构职责：
// - 监听 AuthProvider 获取当前用户信息（用于页面展示和传递给 ViewModel）
// - 通过 BasePage 创建 MineViewModel 并管理 loading 状态
// - 提供退出登录按钮，点击后调用 AuthProvider.logout() 并跳转到登录页
// - 用户信息优先使用 MineViewModel 的数据，其次使用 AuthProvider 的数据
//
// 页面结构：
// AppBar（标题：我的）
//   └── BasePage<MineViewModel>
//        └── Card（用户信息：头像 + 昵称 + 邮箱）
//        └── ElevatedButton（退出登录）

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_page.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../global/auth_provider.dart';
import '../view_model/mine_view_model.dart';

/// 我的 Tab 页面。
///
/// 退出登录由全局 AuthProvider 处理，页面跳转交给 GoRouter。
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听 AuthProvider，退出登录后页面会自动刷新
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mine)),
      body: BasePage<MineViewModel>(
        create: MineViewModel.new,

        // 把 AuthProvider 的 currentUser 传给 ViewModel
        // currentUser 来自全局登录态
        onModelReady: (viewModel) =>
            viewModel.loadMine(authProvider.currentUser),
        onRetry: (viewModel) => viewModel.loadMine(authProvider.currentUser),

        builder: (context, viewModel) {
          // ViewModel 加载完成前，先使用 AuthProvider 中已有的用户信息兜底
          final user = viewModel.user ?? authProvider.currentUser;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ---- 用户信息卡片 ----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      // 头像占位：使用 CircleAvatar + 人物图标
                      const CircleAvatar(
                        radius: 36,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(height: 16),
                      // 用户昵称
                      Text(
                        user?.name ?? '-',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      // 用户邮箱
                      Text(user?.email ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---- 退出登录按钮 ----
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
                // 红色警告样式
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 执行退出登录流程。
  ///
  /// 流程：
  /// 1. 调用 AuthProvider.logout() 清空 token 和用户信息
  /// 2. AuthProvider 会 notifyListeners，GoRouter 重新执行路由守卫
  /// 3. 主动跳转到登录页，让用户看到退出后的页面
  Future<void> _logout(BuildContext context) async {
    // 退出登录必须走 AuthProvider
    // 确保 token、本地用户信息、路由守卫都同步更新
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      // 主动跳登录页，让用户马上看到退出后的页面
      context.go(RoutePaths.login);
    }
  }
}
