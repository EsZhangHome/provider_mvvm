// lib/core/network/dio_interceptor.dart
import 'package:dio/dio.dart';

import '../config/env_config.dart';
import '../utils/logger.dart';

// 请求前自动塞 token，页面和 Repository 不需要手动写 Authorization。
class TokenInterceptor extends Interceptor {
  TokenInterceptor({required this.tokenProvider});

  final String? Function() tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// 简单日志拦截器，只在 debug 模式打印，方便开发期排查接口问题。
class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.log('${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.log(
        'Response ${response.statusCode}: ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.log('Dio error ${err.response?.statusCode}: ${err.message}');
    handler.next(err);
  }
}

// 401 并发保护。多个接口同时返回 401 时，只处理第一次，避免重复 logout/跳转。
class UnauthorizedGuard {
  UnauthorizedGuard({required this.onUnauthorized});

  final void Function() onUnauthorized;
  bool _isHandling = false;

  void handle() {
    if (_isHandling) {
      return;
    }
    _isHandling = true;
    onUnauthorized();
  }

  // 用户重新登录后调用，允许新的登录会话再次响应 401。
  void reset() {
    _isHandling = false;
  }
}

// 统一处理 401。真实项目里可以在这里扩展刷新 token，当前先通知 AuthProvider 退出登录。
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({required this.guard});

  final UnauthorizedGuard guard;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      guard.handle();
    }
    handler.next(err);
  }
}

// 超时或连接异常自动重试，适合弱网环境下减少偶发失败。
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    int? retryCount,
    List<int>? retryDelays,
  })  : retryCount = retryCount ?? EnvConfig.retryCount,
        retryDelays = retryDelays ?? const [1, 2];

  final Dio dio;
  final int retryCount;
  final List<int> retryDelays;

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryIndex = err.requestOptions.extra['retryIndex'] as int? ?? 0;
    if (retryIndex >= retryCount) {
      handler.next(err);
      return;
    }

    final delaySeconds = retryDelays[
        retryIndex < retryDelays.length ? retryIndex : retryDelays.length - 1];
    await Future<void>.delayed(Duration(seconds: delaySeconds));

    err.requestOptions.extra['retryIndex'] = retryIndex + 1;
    try {
      handler.resolve(await dio.fetch<dynamic>(err.requestOptions));
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return false;
    }
  }
}
