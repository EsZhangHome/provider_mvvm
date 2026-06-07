// lib/features/mine/view_model/mine_view_model.dart
import '../../../core/base/base_view_model.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/models/user_model.dart';

// 我的页自己的 ViewModel，只维护我的页需要展示的数据。
class MineViewModel extends BaseViewModel {
  UserModel? user;

  Future<void> loadMine(UserModel? currentUser) async {
    if (currentUser == null) {
      // 理论上未登录用户会被路由守卫拦到登录页。
      // 这里仍然做兜底，避免异常状态下页面空指针。
      setError(AppStrings.userMissing);
      return;
    }
    final loadedUser = await asyncRequest<UserModel>(
      () async {
        // 当前没有独立“我的页”接口，先用当前登录用户模拟一次异步加载。
        // 后续接真实接口时，把这里替换为 MineRepository.fetchMine。
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return currentUser;
      },
    );
    if (loadedUser != null) {
      // 保存我的页展示所需的数据。
      user = loadedUser;
      safeNotifyListeners();
    }
  }
}
