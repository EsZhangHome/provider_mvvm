// lib/features/mine/view/mine_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_page.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../global/auth_provider.dart';
import '../view_model/mine_view_model.dart';

// 我的 Tab。退出登录由全局 AuthProvider 处理，页面跳转交给 GoRouter。
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    // MinePage 需要展示当前用户信息，所以监听 AuthProvider。
    // 退出登录后 AuthProvider 会变化，页面也会随之刷新。
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mine)),
      body: BasePage<MineViewModel>(
        create: MineViewModel.new,

        // MineViewModel 只加载“我的页”需要的数据。
        // currentUser 仍然来自全局登录态 AuthProvider。
        onModelReady: (viewModel) =>
            viewModel.loadMine(authProvider.currentUser),
        onRetry: (viewModel) => viewModel.loadMine(authProvider.currentUser),
        builder: (context, viewModel) {
          // ViewModel 加载完成前，先用 AuthProvider 中已有的用户信息兜底。
          final user = viewModel.user ?? authProvider.currentUser;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? '-',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(user?.email ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
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

  Future<void> _logout(BuildContext context) async {
    // 退出登录必须走 AuthProvider，确保 token、本地用户信息、路由守卫都同步更新。
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      // 主动跳登录页，让用户马上看到退出后的页面。
      context.go(RoutePaths.login);
    }
  }
}
