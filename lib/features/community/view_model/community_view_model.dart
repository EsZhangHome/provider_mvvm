// lib/features/community/view_model/community_view_model.dart
import '../../../core/base/base_view_model.dart';

// 社区页自己的 ViewModel。这里先放模拟帖子数据，后续可接 CommunityRepository。
class CommunityViewModel extends BaseViewModel {
  // 社区帖子列表。这里用 String 简化示例，真实项目建议定义 PostModel。
  final List<String> postList = [];

  Future<void> loadCommunity() async {
    final posts = await asyncRequest<List<String>>(
      () async {
        // 模拟网络请求耗时。
        // 接入真实接口后，这里应调用 CommunityRepository。
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return const [
          'Provider 如何做依赖注入？',
          'MVVM 中 ViewModel 应该写什么？',
          'Dio 拦截器的 token 刷新实践',
        ];
      },
      isEmpty: (data) => data.isEmpty,
    );
    if (posts != null) {
      // 使用 clear + addAll 可以保持 postList 引用不变。
      // 如果页面或测试持有这个 List 引用，不会因为整体替换而失效。
      postList
        ..clear()
        ..addAll(posts);
      safeNotifyListeners();
    }
  }
}
