// lib/features/profile/view/profile_page.dart
//
// 作用：个人中心页面，展示用户详细信息和退出登录入口。
//
// 架构职责：
// - 监听 AuthProvider 获取当前用户信息
// - 通过 BasePage 创建 ProfileViewModel 并管理 loading 状态
// - 通过 get_it 获取 ProfileViewModel 实例
// - 提供退出登录按钮
//
// 页面结构：
// AppBar（标题：个人中心）
//   └── BasePage<ProfileViewModel>
//        └── Card（用户信息：头像 + 昵称 + 邮箱）
//        └── ElevatedButton（退出登录）

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_page.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../global/auth_provider.dart';
import '../view_model/profile_view_model.dart';

/// 个人中心页面。
///
/// 展示用户信息，并通过 AuthProvider 退出登录。
/// 与 MinePage 类似，但有独立的 ProfileViewModel 和 ProfileRepository，
/// 后续可以展示更详细的用户资料。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听 AuthProvider，用户信息变化或退出登录后页面会自动刷新
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: BasePage<ProfileViewModel>(
        // 通过 get_it 创建 ViewModel，每次页面创建时获取新实例
        create: () => locator<ProfileViewModel>(),

        // 把 AuthProvider 的 currentUser 传给 ViewModel
        onModelReady: (viewModel) =>
            viewModel.loadProfile(authProvider.currentUser),
        onRetry: (viewModel) => viewModel.loadProfile(authProvider.currentUser),

        builder: (context, viewModel) {
          // ViewModel 加载完成前，先用 AuthProvider 的用户信息兜底
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
                      // 头像占位
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
              const SizedBox(height: AppSpacing.xl),

              // ---- 退出登录按钮 ----
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

  /// 执行退出登录流程。
  ///
  /// 流程：
  /// 1. 调用 AuthProvider.logout() 清空 token 和用户信息
  /// 2. 主动跳转到登录页
  Future<void> _logout(BuildContext context) async {
    // 退出登录后清理 token，再跳回登录页
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      context.go(RoutePaths.login);
    }
  }
}