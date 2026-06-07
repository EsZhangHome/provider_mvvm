// lib/core/utils/crash_reporter.dart
import 'logger.dart';

// 全局异常上报入口。现在只打日志，后续可在这里接 Sentry、Bugly 等平台。
class CrashReporter {
  const CrashReporter._();

  static void report(Object error, StackTrace? stack) {
    // 当前阶段只打印日志。
    // 真实项目接入线上平台时，可以在这里补充设备信息、用户信息、版本号等上下文。
    AppLogger.log('CrashReporter error: $error');
    if (stack != null) {
      AppLogger.log(stack);
    }
  }
}
