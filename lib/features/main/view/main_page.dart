// lib/features/main/view/main_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../community/view/community_page.dart';
import '../../home/view/home_page.dart';
import '../../mine/view/mine_page.dart';
import '../view_model/main_view_model.dart';

// 登录后的主页面。它只负责组织三个 Tab，不处理任何 Tab 的业务数据。
class MainPage extends StatelessWidget {
  const MainPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainViewModel(initialIndex: initialIndex),
      child: Consumer<MainViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            // IndexedStack 会保留三个子页面的状态，切换 Tab 不会反复创建页面。
            body: IndexedStack(
              index: viewModel.tabIndex,
              children: const [
                HomePage(),
                CommunityPage(),
                MinePage(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: viewModel.tabIndex,
              onTap: viewModel.setTabIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: AppStrings.home,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum),
                  label: AppStrings.community,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: AppStrings.mine,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
