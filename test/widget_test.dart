// test/widget_test.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/app.dart';
import 'package:provider_mvvm/core/di/service_locator.dart';
import 'package:provider_mvvm/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app starts at login page when there is no token',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorage.init();
    await setupServiceLocator();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('登录'), findsWidgets);
    expect(find.text('Provider MVVM'), findsOneWidget);
  });
}
