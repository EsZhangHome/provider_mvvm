// lib/main.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/crash_reporter.dart';

Future<void> main() async {
  FlutterError.onError = _onFlutterError;
  PlatformDispatcher.instance.onError = _onPlatformError;

  // 使用插件前先绑定 Flutter 引擎，比如 SharedPreferences 就需要这一步。
  WidgetsFlutterBinding.ensureInitialized();

  // 统一初始化本地存储，业务代码不要直接操作 SharedPreferences。
  try {
    await LocalStorage.init();
  } catch (error, stack) {
    CrashReporter.report(error, stack);
  }

  await setupServiceLocator();

  // MyApp 只负责组装 Provider、主题和路由，具体业务放到 features 里。
  runApp(const MyApp());
}

void _onFlutterError(FlutterErrorDetails details) {
  FlutterError.presentError(details);
  CrashReporter.report(details.exception, details.stack);
}

bool _onPlatformError(Object error, StackTrace stack) {
  CrashReporter.report(error, stack);
  return true;
}
