// lib/features/home/view/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_page.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../global/theme_provider.dart';
import '../view_model/home_view_model.dart';

// 首页：通过 BasePage 自动展示 loading/error/empty/content。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.home),
        actions: [
          IconButton(
            tooltip: AppStrings.switchTheme,
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: const Icon(Icons.brightness_6_outlined),
          ),
        ],
      ),
      body: BasePage<HomeViewModel>(
        create: () => locator<HomeViewModel>(),
        // 首帧渲染后请求数据，避免在 build 过程中触发状态刷新。
        onModelReady: (viewModel) => viewModel.loadHome(),
        onRetry: (viewModel) => viewModel.loadHome(),
        builder: (context, viewModel) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: viewModel.bannerList.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final banner = viewModel.bannerList[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(banner.title),
                  subtitle: const Text(AppStrings.mockBannerTips),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
