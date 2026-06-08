// test/core/di/service_locator_test.dart
//
// 依赖注入是整套架构的入口之一。
// 这里确认基础服务都已注册，后续 Repository / ViewModel 才能通过抽象拿到能力。

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/core/app/app_info_service.dart';
import 'package:provider_mvvm/core/database/database_service.dart';
import 'package:provider_mvvm/core/database/sqlite_database_service.dart';
import 'package:provider_mvvm/core/di/service_locator.dart';
import 'package:provider_mvvm/core/network/network_status_service.dart';
import 'package:provider_mvvm/core/permission/permission_service.dart';

void main() {
  tearDown(() async {
    await locator.reset();
  });

  test('service locator registers common service abstractions', () async {
    await locator.reset();
    await setupServiceLocator();

    expect(locator.isRegistered<DatabaseService>(), isTrue);
    expect(locator<DatabaseService>(), isA<SqliteDatabaseService>());

    expect(locator.isRegistered<NetworkStatusService>(), isTrue);
    expect(
      locator<NetworkStatusService>(),
      isA<ConnectivityNetworkStatusService>(),
    );

    expect(locator.isRegistered<PermissionService>(), isTrue);
    expect(locator<PermissionService>(), isA<PermissionHandlerService>());

    expect(locator.isRegistered<AppInfoService>(), isTrue);
    expect(locator<AppInfoService>(), isA<PackageInfoAppInfoService>());
  });
}
