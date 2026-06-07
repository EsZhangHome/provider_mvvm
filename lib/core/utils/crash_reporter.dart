// lib/core/utils/crash_reporter.dart
import 'logger.dart';

// 全局异常上报入口。现在只打日志，后续可在这里接 Sentry、Bugly 等平台。
class CrashReporter {
  const CrashReporter._();

  static void report(Object error, StackTrace? stack) {
    AppLogger.log('CrashReporter error: $error');
    if (stack != null) {
      AppLogger.log(stack);
    }
  }
}
