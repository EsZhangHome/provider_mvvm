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

  // 页面可以通过这个 getter 判断当前 ViewModel 是否已经拿到登录态。
  bool get isLogin => token != null && token!.isNotEmpty;

  // 返回 bool 是为了让页面知道是否登录成功，成功后再跳转。
  Future<bool> login(String account, String password) async {
    if (account.trim().isEmpty || password.trim().isEmpty) {
      // 表单校验属于页面业务逻辑，放在 ViewModel 中更容易测试。
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
      // asyncRequest 返回 null 表示请求失败、被取消、或被防抖拦截。
      return false;
    }

    // 只把 View 层需要的数据暴露为清晰字段。
    // View 不需要知道 LoginResponse 的完整结构。
    token = response.token;
    user = response.user;
    return true;
  }
}
