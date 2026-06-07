// lib/features/main/view/main_page.dart
//
// 作用：登录后的主框架页，通过 IndexedStack + BottomNavigationBar 管理三个 Tab。
//
// 架构职责：
// - 持有 MainViewModel（管理底部 Tab 下标）
// - 通过 IndexedStack 保留三个子页面的状态（切换 Tab 不会销毁页面）
// - 通过 BottomNavigationBar 提供 Tab 切换入口
// - 不处理任何 Tab 的业务数据
//
// 设计要点：
// 1. IndexedStack：切换 Tab 时子页面保留在树中，不会 dispose
//    - 好处：滚动位置、请求结果、页面状态都能保留
//    - 代价：三个页面同时存在，内存占用稍高（对于 3 个 Tab 可接受）
// 2. 外部路由 /main/home、/main/community、/main/mine 通过 initialIndex 指定默认 Tab
// 3. 点击底部 Tab 只改变 tabIndex，不触发路由跳转（更轻量）

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../community/view/community_page.dart';
import '../../home/view/home_page.dart';
import '../../mine/view/mine_page.dart';
import '../view_model/main_view_model.dart';

/// 登录后的主框架页。
///
/// 只负责组织三个 Tab 的布局和切换，不处理任何业务数据。
/// 每个 Tab 页面有自己的独立 ViewModel，通过 IndexedStack 保持状态。
class MainPage extends StatelessWidget {
  const MainPage({
    super.key,
    this.initialIndex = 0,
  });

  /// 初始选中的 Tab 下标。
  /// 外部通过 /main/home（0）、/main/community（1）、/main/mine（2）路径传入。
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider 管理 MainViewModel 的生命周期
    // MainViewModel 是 MainPage 私有状态，只管理底部 Tab 下标
    return ChangeNotifierProvider(
      create: (_) => MainViewModel(initialIndex: initialIndex),
      child: Consumer<MainViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            // ---- 页面主体：IndexedStack ----
            // IndexedStack 会根据 index 展示对应的子页面
            // 切换 Tab 时不会销毁其他子页面，它们的状态会保留
            body: IndexedStack(
              index: viewModel.tabIndex,
              children: const [
                // Tab 0：首页
                HomePage(),
                // Tab 1：社区
                CommunityPage(),
                // Tab 2：我的
                MinePage(),
              ],
            ),

            // ---- 底部导航栏 ----
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: viewModel.tabIndex,
              // 点击底部 Tab 只改变 tabIndex，不做路由跳转
              // 这样切换更轻量，也不会反复创建页面
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