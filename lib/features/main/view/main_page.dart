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

  // 外部直接访问 /main/community 或 /main/mine 时，
  // AppRouter 会传入对应 initialIndex，让 MainPage 打开指定 Tab。
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // MainViewModel 是 MainPage 私有状态，只管理底部 Tab 下标。
      // 三个 Tab 的业务数据分别由自己的 ViewModel 管理。
      create: (_) => MainViewModel(initialIndex: initialIndex),
      child: Consumer<MainViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            // IndexedStack 会保留三个子页面的状态，切换 Tab 不会反复创建页面。
            body: IndexedStack(
              index: viewModel.tabIndex,
              children: const [
                // 三个页面会同时保留在树中。
                // 切换 Tab 时不会 dispose，因此滚动位置、请求结果和页面状态都能保留。
                HomePage(),
                CommunityPage(),
                MinePage(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: viewModel.tabIndex,
              // 点击底部 Tab 只改变 tabIndex，不做路由跳转。
              // 这样切换更轻量，也不会反复创建页面。
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
