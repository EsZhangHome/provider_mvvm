// lib/features/home/view/home_page.dart
//
// 作用：首页页面，展示 Banner 列表。
//
// 架构职责：
// - 通过 BasePage 自动管理 loading/error/empty/content 状态
// - 通过 get_it 获取 HomeViewModel 实例
// - 在 AppBar 提供主题切换按钮
// - 只负责 UI 展示，不处理数据加载逻辑
//
// 数据流：
// 1. 页面创建 → BasePage 创建 HomeViewModel
// 2. onModelReady 触发 → viewModel.loadHome()
// 3. ViewModel 请求数据 → 自动切换 loading/error/empty/success
// 4. BasePage 的 StateView 根据状态展示不同 UI
// 5. 成功后 → builder 中渲染 Banner 列表

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_page.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../global/theme_provider.dart';
import '../view_model/home_view_model.dart';

/// 首页页面。
///
/// 通过 BasePage 自动展示 loading/error/empty/content。
/// 页面本身只需要关心"数据正常时怎么展示 UI"。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar：标题 + 主题切换按钮
      appBar: AppBar(
        title: const Text(AppStrings.home),
        actions: [
          // 主题切换按钮：点击后切换明暗主题
          IconButton(
            tooltip: AppStrings.switchTheme,
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: const Icon(Icons.brightness_6_outlined),
          ),
        ],
      ),
      // 页面主体：使用 BasePage 自动管理状态
      body: BasePage<HomeViewModel>(
        // 通过 get_it 创建 ViewModel，每次页面创建时获取新实例
        create: () => locator<HomeViewModel>(),

        // 首帧渲染后请求数据，避免在 build 过程中触发状态刷新
        onModelReady: (viewModel) => viewModel.loadHome(),

        // ErrorView 点击重试时调用，重新加载数据
        onRetry: (viewModel) => viewModel.loadHome(),

        // 正常内容构建器：loading/error/empty 已被 BasePage + StateView 接管
        // 这里能执行到，说明当前状态是 idle 或 success
        builder: (context, viewModel) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // Banner 列表项数量
            itemCount: viewModel.bannerList.length,
            // 分隔线
            separatorBuilder: (_, index) =>
                const SizedBox(height: AppSpacing.md),
            // 列表项：当前用 Card + ListTile 展示模拟 banner
            // 接入真实图片时，可以把 leading/subtitle 替换成图片组件
            itemBuilder: (context, index) {
              final banner = viewModel.bannerList[index];
              return Card(
                child: ListTile(
                  // 序号图标
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  // Banner 标题
                  title: Text(banner.title),
                  // 模拟数据提示
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
