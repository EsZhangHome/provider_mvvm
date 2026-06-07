// test/features/login/login_view_model_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
  test('login view model can be tested with a repository interface', () async {
    final viewModel = LoginViewModel(FakeLoginRepository());

    final success = await viewModel.login('test@example.com', '123456');

    expect(success, isTrue);
    expect(viewModel.token, 'fake_token');
    expect(viewModel.user?.name, 'Test User');
  });
}
