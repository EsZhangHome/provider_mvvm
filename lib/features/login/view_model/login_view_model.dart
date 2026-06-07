// lib/features/login/view_model/login_view_model.dart
import '../../../core/base/base_view_model.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/models/user_model.dart';
import '../model/login_request.dart';
import '../repository/login_repository.dart';

// 登录页的状态和业务逻辑都放这里，页面只负责收集输入和展示结果。
class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._repository);

  final LoginRepository _repository;

  UserModel? user;
  String? token;
  bool get isLogin => token != null && token!.isNotEmpty;

  // 返回 bool 是为了让页面知道是否登录成功，成功后再跳转。
  Future<bool> login(String account, String password) async {
    if (account.trim().isEmpty || password.trim().isEmpty) {
      setError(AppStrings.enterAccountAndPassword);
      return false;
    }

    final response = await asyncRequest(
      // asyncRequest 会自动处理 loading/error/success，避免页面里写重复逻辑。
      () => _repository.login(
        LoginRequest(account: account.trim(), password: password.trim()),
        cancelToken: cancelToken,
      ),
      cancelToken: cancelToken,
    );
    if (response == null) {
      return false;
    }
    token = response.token;
    user = response.user;
    return true;
  }
}
