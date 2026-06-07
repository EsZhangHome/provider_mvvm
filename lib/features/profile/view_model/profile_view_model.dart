// lib/features/profile/view_model/profile_view_model.dart
import '../../../core/base/base_view_model.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/models/user_model.dart';
import '../repository/profile_repository.dart';

// 个人中心 ViewModel：负责加载用户信息和维护页面状态。
class ProfileViewModel extends BaseViewModel {
  ProfileViewModel(this._repository);

  final ProfileRepository _repository;

  UserModel? user;

  // currentUser 来自 AuthProvider，作为没有真实接口时的兜底数据。
  Future<void> loadProfile(UserModel? currentUser) async {
    if (currentUser == null) {
      // 未登录用户理论上无法访问受保护页面，但这里仍做防御式处理。
      setError(AppStrings.userMissing);
      return;
    }
    final profile = await asyncRequest<UserModel>(
      () => _repository.fetchProfile(currentUser, cancelToken: cancelToken),
      cancelToken: cancelToken,
    );
    if (profile != null) {
      // 只暴露页面需要展示的用户字段。
      user = profile;
      safeNotifyListeners();
    }
  }
}
