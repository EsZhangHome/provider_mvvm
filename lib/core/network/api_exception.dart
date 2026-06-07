// lib/core/network/api_exception.dart
import 'package:dio/dio.dart';

import '../l10n/app_strings.dart';

// 网络层统一异常。ViewModel 只关心 message，不需要知道 Dio 的复杂错误类型。
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
  });

  final int code;
  final String message;

  static const int networkError = -1;
  static const int timeoutError = -2;
  static const int serverError = -3;
  static const int unknownError = -4;

  factory ApiException.fromDioException(DioException error) {
    // DioExceptionType 能区分超时、取消、服务器返回错误等情况。
    // 这里把 Dio 的错误类型转换成用户能理解的文案。
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            code: timeoutError, message: AppStrings.requestTimeout);
      case DioExceptionType.badResponse:
        return ApiException(
          code: error.response?.statusCode ?? serverError,
          message: _messageFromResponse(error.response),
        );
      case DioExceptionType.cancel:
        return const ApiException(
            code: networkError, message: AppStrings.requestCanceled);
      case DioExceptionType.connectionError:
        return const ApiException(
            code: networkError, message: AppStrings.networkError);
      case DioExceptionType.badCertificate:
        return const ApiException(
            code: networkError, message: AppStrings.certificateError);
      case DioExceptionType.unknown:
        return const ApiException(
            code: unknownError, message: AppStrings.unknownError);
    }
  }

  static String _messageFromResponse(Response<dynamic>? response) {
    // 如果后端错误响应里已经有 message，就优先使用后端文案。
    // 否则使用统一的服务器异常提示。
    final data = response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return AppStrings.serverError;
  }

  @override
  String toString() => message;
}

class BusinessException extends ApiException {
  BusinessException({
    required int code,
    required this.userMessage,
  }) : super(code: code, message: userMessage);

  final String userMessage;
}
