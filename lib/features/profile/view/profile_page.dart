// lib/features/profile/view/profile_page.dart
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

// 个人中心页面：展示用户信息，并通过 AuthProvider 退出登录。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch 会监听用户信息变化，比如退出登录后页面会刷新。
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: BasePage<ProfileViewModel>(
        create: () => locator<ProfileViewModel>(),
        onModelReady: (viewModel) =>
            viewModel.loadProfile(authProvider.currentUser),
        onRetry: (viewModel) => viewModel.loadProfile(authProvider.currentUser),
        builder: (context, viewModel) {
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
              const SizedBox(height: AppSpacing.xl),
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
    // 退出登录后清理 token，再跳回登录页。
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      context.go(RoutePaths.login);
    }
  }
}
