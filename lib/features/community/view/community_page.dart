// lib/features/community/view/community_page.dart
//
// 作用：社区 Tab 页面，展示社区帖子列表。
//
// 架构职责：
// - 通过 BasePage 自动管理 loading/error/empty/content 状态
// - 有自己的 CommunityViewModel，不依赖 MainViewModel
// - 当前展示模拟帖子列表，后续可替换为真实社区内容
//
// 数据流：
// 1. 页面创建 → BasePage 创建 CommunityViewModel
// 2. onModelReady 触发 → viewModel.loadCommunity()
// 3. ViewModel 请求数据 → 自动切换 loading/error/empty/success
// 4. BasePage 的 StateView 根据状态展示不同 UI
// 5. 成功后 → builder 中渲染帖子列表

import 'package:flutter/material.dart';

import '../../../core/base/base_page.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../view_model/community_view_model.dart';

/// 社区 Tab 页面。
///
/// 有自己的 CommunityViewModel，不依赖 MainViewModel 存放业务数据。
/// 后续接真实接口时，可以按 Home 模块一样补 CommunityRepository。
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.community)),
      body: BasePage<CommunityViewModel>(
        // 社区页暂时没有 Repository，ViewModel 内部使用模拟数据
        // 后续接真实接口时，通过 get_it 创建：
        // create: () => locator<CommunityViewModel>()
        create: CommunityViewModel.new,

        // 首帧渲染后请求数据
        onModelReady: (viewModel) => viewModel.loadCommunity(),

        // ErrorView 点击重试时调用
        onRetry: (viewModel) => viewModel.loadCommunity(),

        // 正常内容构建器：loading/error/empty 已被 StateView 接管
        builder: (context, viewModel) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: viewModel.postList.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              // 当前只是帖子标题列表，后续可以替换成 PostCard 组件
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(viewModel.postList[index]),
                  subtitle: const Text(AppStrings.communityMockTips),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
