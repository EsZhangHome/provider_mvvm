// lib/features/community/view/community_page.dart
import 'package:flutter/material.dart';

import '../../../core/base/base_page.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../view_model/community_view_model.dart';

// 社区 Tab。它有自己的 CommunityViewModel，不依赖 MainViewModel 存业务数据。
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.community)),
      body: BasePage<CommunityViewModel>(
        // 社区页暂时没有 Repository，ViewModel 内部使用模拟数据。
        // 后续接真实接口时，可以按 Home 模块一样补 CommunityRepository。
        create: CommunityViewModel.new,
        onModelReady: (viewModel) => viewModel.loadCommunity(),
        onRetry: (viewModel) => viewModel.loadCommunity(),
        builder: (context, viewModel) {
          // 能进入 builder 说明 StateView 已经处理完 loading/error/empty。
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: viewModel.postList.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              // 当前只是帖子标题列表，后续可以替换成 PostCard 组件。
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
