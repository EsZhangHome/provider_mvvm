// test/core/router/app_router_test.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/core/router/app_router.dart';
import 'package:provider_mvvm/core/router/route_guard.dart';
import 'package:provider_mvvm/global/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('app router keeps the same GoRouter instance', () {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final authProvider = AuthProvider();
    final appRouter = AppRouter(
      authProvider,
      guards: [AuthRouteGuard(authProvider)],
    );

    final firstRouter = appRouter.config;
    final secondRouter = appRouter.config;

    expect(identical(firstRouter, secondRouter), isTrue);
  });
}
