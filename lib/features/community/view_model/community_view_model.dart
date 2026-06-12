// lib/features/community/view_model/community_view_model.dart
//
// 作用：社区页 ViewModel，负责社区数据加载和状态管理。
//
// 架构职责：
// - 持有 postList，暴露给页面展示
// - 提供 loadCommunity 方法，页面通过 onModelReady 调用
// - 继承 BaseViewModel，自动获得 loading/error/empty/success 状态管理
// - 当前使用模拟数据，后续接入真实接口时替换为 CommunityRepository
//
// 扩展方式：
// 1. 定义 CommunityPost 模型（标题、内容、作者、时间等）
// 2. 创建 CommunityRepository 接口和实现
// 3. 在 service_locator 中注册
// 4. 修改 loadCommunity 中的模拟数据为 repository 调用

import '../../../core/base/base_view_model.dart';

/// 社区页 ViewModel。
///
/// 当前使用模拟数据，后续接入真实接口时，
/// 可以按 Home 模块一样补 CommunityRepository 和 CommunityPost 模型。
class CommunityViewModel extends BaseViewModel {
  /// 社区帖子列表，当前用 String 简化示例。
  /// 真实项目建议定义 PostModel，包含标题、内容、作者、时间等字段。
  final List<String> postList = [];

  /// 加载社区数据。
  ///
  /// 调用时机：页面 onModelReady 时调用。
  Future<void> loadCommunity() async {
    final posts = await asyncRequest<List<String>>(
      () async {
        // 模拟网络请求耗时
        // 接入真实接口后，这里应调用 CommunityRepository
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return const [
          'Provider 如何做依赖注入？',
          'MVVM 中 ViewModel 应该写什么？',
          'Dio 拦截器的 token 刷新实践',
        ];
      },
      // 判断数据是否为空
      isEmpty: (data) => data.isEmpty,
    );

    if (posts != null) {
      // 使用 clear + addAll 保持 postList 引用不变
      // 如果页面或测试持有这个 List 引用，不会因为整体替换而失效
      postList
        ..clear()
        ..addAll(posts);
      safeNotifyListeners();
    }
  }
}
