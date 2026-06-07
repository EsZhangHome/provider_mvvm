// lib/main.dart
//
// 作用：App 的入口文件，负责初始化顺序和全局异常捕获。
//
// 启动流程：
// 1. 注册全局异常捕获（FlutterError.onError, PlatformDispatcher）
// 2. 绑定 Flutter 引擎（WidgetsFlutterBinding.ensureInitialized）
// 3. 初始化本地存储（LocalStorage.init）
// 4. 注册依赖注入（setupServiceLocator）
// 5. 启动 App（runApp）
//
// 设计要点：
// - 初始化顺序很重要：存储必须在 DI 之前初始化，因为某些依赖可能依赖存储
// - 异常捕获不能阻断 App 启动：存储初始化失败时只记录错误，继续启动
// - main() 函数保持简洁，不包含业务逻辑，业务逻辑都在 App 内部

import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/crash_reporter.dart';

/// App 入口函数。
///
/// 所有初始化逻辑都在这里按顺序执行，确保 App 启动时依赖就绪。
/// runApp 之前的代码如果抛出异常，App 将无法启动，所以需要 try-catch 保护。
Future<void> main() async {
  // ==================== 步骤 1：注册全局异常捕获 ====================

  // 捕获 Flutter 框架层面的异常（build/layout/paint 阶段的错误）
  // 注意：这里不弹窗、不阻塞 UI，只统一交给 CrashReporter 记录
  FlutterError.onError = _onFlutterError;

  // 捕获 Dart 异步 Zone 外的异常（Future、插件回调、平台通道中的未捕获错误）
  // 返回 true 表示这个异常已经被我们处理，避免 App 因未捕获异常直接退出
  PlatformDispatcher.instance.onError = _onPlatformError;

  // ==================== 步骤 2：绑定 Flutter 引擎 ====================

  // 使用插件前必须先绑定 Flutter 引擎
  // 例如 SharedPreferences、flutter_secure_storage 都需要这一步
  WidgetsFlutterBinding.ensureInitialized();

  // ==================== 步骤 3：初始化本地存储 ====================

  // 统一初始化本地存储，业务代码不要直接操作 SharedPreferences
  // 初始化失败时只记录日志并继续启动 App，避免本地存储问题影响用户打开应用
  try {
    await LocalStorage.init();
  } catch (error, stack) {
    CrashReporter.report(error, stack);
  }

  // ==================== 步骤 4：注册依赖注入 ====================

  // 注册 Repository、ViewModel、ApiService 等依赖
  // 页面里通过 locator<T>() 获取对象，避免到处手动 new
  // 后续也方便替换 fake 实现做单元测试
  await setupServiceLocator();

  // ==================== 步骤 5：启动 App ====================

  // MyApp 只负责组装 Provider、主题和路由，具体业务放到 features 里
  runApp(const MyApp());
}

/// Flutter 框架层面的异常处理器。
///
/// 在 build/layout/paint 阶段抛出的错误会通过这个回调上报。
/// 保留 Flutter 默认的错误输出，同时把错误交给 CrashReporter 上报。
void _onFlutterError(FlutterErrorDetails details) {
  // 保留 Flutter 默认错误输出，debug 控制台仍能看到红色错误栈
  FlutterError.presentError(details);

  // 把错误交给统一上报入口，后续接 Sentry/Bugly 只需要改 CrashReporter
  CrashReporter.report(details.exception, details.stack);
}

/// 平台层面的异常处理器。
///
/// 捕获 Dart 异步 Zone 外的异常，如 Future、插件回调、平台通道中的未捕获错误。
///
/// 返回值：true 表示错误已处理，false 表示继续交给系统处理（可能导致崩溃）。
/// 这里返回 true 以确保 App 不会因为未捕获异常直接退出。
bool _onPlatformError(Object error, StackTrace stack) {
  CrashReporter.report(error, stack);
  return true;
}