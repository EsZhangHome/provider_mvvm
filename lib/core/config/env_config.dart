// lib/core/config/env_config.dart
import 'package:flutter/foundation.dart';

// 环境配置统一入口。启动 App 时可以通过 --dart-define 覆盖这些默认值。
class EnvConfig {
  const EnvConfig._();

  // 接口域名。示例：
  // flutter run --dart-define=ENV_API_BASE_URL=https://dev-api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'ENV_API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  // Dio 建立连接的最长等待时间，单位：秒。
  static const int connectTimeout = int.fromEnvironment(
    'ENV_CONNECT_TIMEOUT',
    defaultValue: 15,
  );

  // Dio 接收响应数据的最长等待时间，单位：秒。
  static const int receiveTimeout = int.fromEnvironment(
    'ENV_RECEIVE_TIMEOUT',
    defaultValue: 15,
  );

  // Dio 发送请求体的最长等待时间，单位：秒。
  static const int sendTimeout = int.fromEnvironment(
    'ENV_SEND_TIMEOUT',
    defaultValue: 15,
  );

  // 网络重试次数，只对超时和连接异常生效。
  static const int retryCount = int.fromEnvironment(
    'ENV_RETRY_COUNT',
    defaultValue: 2,
  );

  // 业务成功码。国内常见接口一般 code == 0 表示成功。
  static const int apiSuccessCode = int.fromEnvironment(
    'ENV_API_SUCCESS_CODE',
    defaultValue: 0,
  );

  // 是否使用 HTTP 状态码判断成功。
  // true：200-299 成功；false：使用 apiSuccessCode 判断成功。
  static const bool useHttpStatus = bool.fromEnvironment(
    'ENV_USE_HTTP_STATUS',
    defaultValue: false,
  );

  // 是否 debug 模式。默认跟随 Flutter 的 kDebugMode。
  static const bool isDebug = bool.fromEnvironment(
    'ENV_IS_DEBUG',
    defaultValue: kDebugMode,
  );
}
