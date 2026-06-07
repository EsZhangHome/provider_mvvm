// lib/features/mine/view_model/mine_view_model.dart
import '../../../core/base/base_view_model.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/models/user_model.dart';

// 我的页自己的 ViewModel，只维护我的页需要展示的数据。
class MineViewModel extends BaseViewModel {
  UserModel? user;

  Future<void> loadMine(UserModel? currentUser) async {
    if (currentUser == null) {
      setError(AppStrings.userMissing);
      return;
    }
    final loadedUser = await asyncRequest<UserModel>(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return currentUser;
      },
    );
    if (loadedUser != null) {
      user = loadedUser;
      safeNotifyListeners();
    }
  }
}
