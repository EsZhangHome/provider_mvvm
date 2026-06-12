// lib/core/utils/crash_reporter.dart
//
// 作用：全局异常上报入口，统一收集和处理 App 中的异常信息。
//
// 当前阶段只打印日志，后续可以在这里接入 Sentry、Bugly、Firebase Crashlytics 等平台。
//
// 接入方式（以 Sentry 为例）：
// ```dart
// static void report(Object error, StackTrace? stack) {
//   Sentry.captureException(error, stackTrace: stack);
//   AppLogger.log('CrashReporter error: $error');
// }
// ```
//
// 设计要点：
// 1. 全 App 只有一个上报入口，main.dart 中 FlutterError.onError 和 PlatformDispatcher 都走这里
// 2. 当前只打日志，后续接入线上平台只需要改这个类，不影响其他代码
// 3. 上报时可以补充设备信息、用户信息、App 版本号等上下文

import 'logger.dart';

/// 全局异常上报入口。
///
/// 所有异常最终都汇集到这里，统一处理。
/// 当前只打日志，后续接入线上崩溃平台时只需要修改这个类。
class CrashReporter {
  const CrashReporter._();

  /// 上报异常。
  ///
  /// [error]：异常对象，可以是 Exception、Error 或任意 Object
  /// [stack]：堆栈信息，可能为 null（如业务层手动上报的简单错误）
  ///
  /// 调用时机：
  /// - FlutterError.onError：Flutter 框架层面的异常（build/layout/paint 阶段）
  /// - PlatformDispatcher.instance.onError：Dart 异步 Zone 外的异常
  /// - try-catch 中手动调用：业务层捕获到的异常
  static void report(Object error, StackTrace? stack) {
    // 当前阶段只打印日志
    // 真实项目接入线上平台时，可以在这里补充：
    // - 设备型号、系统版本
    // - App 版本号、渠道号
    // - 当前登录用户 ID
    // - 当前页面路由
    AppLogger.log('CrashReporter error: $error');
    if (stack != null) {
      AppLogger.log(stack);
    }
  }
}
