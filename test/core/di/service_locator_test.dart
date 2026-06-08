// test/core/di/service_locator_test.dart
//
// 依赖注入是整套架构的入口之一。
// 这里确认 DatabaseService 已经注册，后续 Repository 才能通过抽象拿到数据库能力。

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/core/database/database_service.dart';
import 'package:provider_mvvm/core/database/sqlite_database_service.dart';
import 'package:provider_mvvm/core/di/service_locator.dart';

void main() {
  tearDown(() async {
    await locator.reset();
  });

  test('service locator registers database service abstraction', () async {
    await locator.reset();
    await setupServiceLocator();

    expect(locator.isRegistered<DatabaseService>(), isTrue);
    expect(locator<DatabaseService>(), isA<SqliteDatabaseService>());
  });
}
