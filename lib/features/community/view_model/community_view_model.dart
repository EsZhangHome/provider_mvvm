// lib/features/community/view_model/community_view_model.dart
import '../../../core/base/base_view_model.dart';

// 社区页自己的 ViewModel。这里先放模拟帖子数据，后续可接 CommunityRepository。
class CommunityViewModel extends BaseViewModel {
  final List<String> postList = [];

  Future<void> loadCommunity() async {
    final posts = await asyncRequest<List<String>>(
      () async {
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
      postList
        ..clear()
        ..addAll(posts);
      safeNotifyListeners();
    }
  }
}
