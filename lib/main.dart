// lib/main.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/crash_reporter.dart';

Future<void> main() async {
  // 捕获 Flutter 框架层面的异常，例如 build/layout/paint 阶段抛出的错误。
  // 这里不弹窗、不阻塞 UI，只统一交给 CrashReporter 记录，方便以后接入线上崩溃平台。
  FlutterError.onError = _onFlutterError;

  // 捕获 Dart 异步 Zone 外的异常，例如 Future、插件回调、平台通道中的未捕获错误。
  // 返回 true 表示这个异常已经被我们处理，避免 App 因未捕获异常直接退出。
  PlatformDispatcher.instance.onError = _onPlatformError;

  // 使用插件前先绑定 Flutter 引擎，比如 SharedPreferences 就需要这一步。
  WidgetsFlutterBinding.ensureInitialized();

  // 统一初始化本地存储，业务代码不要直接操作 SharedPreferences。
  // 即使初始化失败，也只记录日志并继续启动 App，避免本地存储问题影响用户打开应用。
  try {
    await LocalStorage.init();
  } catch (error, stack) {
    CrashReporter.report(error, stack);
  }

  // 注册 Repository、ViewModel、ApiService 等依赖。
  // 页面里通过 locator<T>() 获取对象，避免到处手动 new，后续也方便替换 fake 实现做测试。
  await setupServiceLocator();

  // MyApp 只负责组装 Provider、主题和路由，具体业务放到 features 里。
  runApp(const MyApp());
}

void _onFlutterError(FlutterErrorDetails details) {
  // 保留 Flutter 默认错误输出，这样 debug 控制台还能看到红色错误栈。
  FlutterError.presentError(details);

  // 再把错误交给统一上报入口。后续接 Sentry/Bugly 只需要改 CrashReporter。
  CrashReporter.report(details.exception, details.stack);
}

bool _onPlatformError(Object error, StackTrace stack) {
  // PlatformDispatcher 的回调必须返回 bool。
  // true 表示错误已处理，false 表示继续交给系统处理并可能导致崩溃。
  CrashReporter.report(error, stack);
  return true;
}
