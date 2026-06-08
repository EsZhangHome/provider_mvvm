// test/features/login/login_view_model_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/core/di/service_locator.dart';
import 'package:provider_mvvm/features/login/model/login_request.dart';
import 'package:provider_mvvm/features/login/model/login_response.dart';
import 'package:provider_mvvm/features/login/repository/login_repository.dart';
import 'package:provider_mvvm/features/login/view_model/login_view_model.dart';
import 'package:provider_mvvm/shared/models/user_model.dart';

class FakeLoginRepository implements LoginRepository {
  @override
  Future<LoginResponse> login(
    LoginRequest request, {
    CancelToken? cancelToken,
  }) async {
    return const LoginResponse(
      token: 'fake_token',
      user: UserModel(id: '1', name: 'Test User', email: 'test@example.com'),
    );
  }
}

void main() {
  setUp(() async {
    await locator.reset();

    // 单元测试里用 get_it 把 LoginRepository 替换成 fake 实现。
    // 这样 ViewModel 的创建方式和真实页面保持一致：都通过 locator 获取依赖。
    locator.registerLazySingleton<LoginRepository>(
      FakeLoginRepository.new,
    );
    locator.registerFactory<LoginViewModel>(
      () => LoginViewModel(locator<LoginRepository>()),
    );
  });

  tearDown(() async {
    await locator.reset();
  });

  test('login view model uses fake repository registered in get_it', () async {
    final viewModel = locator<LoginViewModel>();

    final success = await viewModel.login('test@example.com', '123456');

    expect(success, isTrue);
    expect(viewModel.token, 'fake_token');
    expect(viewModel.user?.name, 'Test User');
  });
}
