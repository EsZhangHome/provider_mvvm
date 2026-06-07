// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

// 简单日志工具。后续可以替换成更完整的日志库，但调用方不用改。
class AppLogger {
  const AppLogger._();

  static void log(Object message) {
    if (kDebugMode) {
      debugPrint('[ProviderMVVM] $message');
    }
  }
}
