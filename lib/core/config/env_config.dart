// lib/core/config/env_config.dart
import 'package:flutter/foundation.dart';

// 环境配置统一入口。启动 App 时可以通过 --dart-define 覆盖这些默认值。
class EnvConfig {
  const EnvConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'ENV_API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const int connectTimeout = int.fromEnvironment(
    'ENV_CONNECT_TIMEOUT',
    defaultValue: 15,
  );

  static const int receiveTimeout = int.fromEnvironment(
    'ENV_RECEIVE_TIMEOUT',
    defaultValue: 15,
  );

  static const int sendTimeout = int.fromEnvironment(
    'ENV_SEND_TIMEOUT',
    defaultValue: 15,
  );

  static const int retryCount = int.fromEnvironment(
    'ENV_RETRY_COUNT',
    defaultValue: 2,
  );

  static const int apiSuccessCode = int.fromEnvironment(
    'ENV_API_SUCCESS_CODE',
    defaultValue: 0,
  );

  static const bool useHttpStatus = bool.fromEnvironment(
    'ENV_USE_HTTP_STATUS',
    defaultValue: false,
  );

  static const bool isDebug = bool.fromEnvironment(
    'ENV_IS_DEBUG',
    defaultValue: kDebugMode,
  );
}
