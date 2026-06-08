// test/core/network/network_status_service_test.dart
//
// 只测试项目自己的状态映射，不测试 connectivity_plus 插件本身。

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/core/network/network_status_service.dart';

void main() {
  group('ConnectivityNetworkStatusService', () {
    test('maps wifi to connected status', () {
      final status = ConnectivityNetworkStatusService.mapConnectivityResult(
        ConnectivityResult.wifi,
      );

      expect(status.type, NetworkConnectionType.wifi);
      expect(status.isConnected, isTrue);
    });

    test('maps none to disconnected status', () {
      final status = ConnectivityNetworkStatusService.mapConnectivityResult(
        ConnectivityResult.none,
      );

      expect(status.type, NetworkConnectionType.none);
      expect(status.isConnected, isFalse);
    });
  });
}
