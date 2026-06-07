// lib/core/network/api_service.dart
import 'package:dio/dio.dart';

import 'api_response.dart';

// 网络服务抽象。Repository 依赖这个接口，测试时可以替换成假的实现。
abstract class ApiService {
  // 读取类请求。
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  });

  // 创建或提交类请求。
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  });

  // 更新类请求。
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  });

  // 删除类请求。
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  });

  // 文件上传请求，例如头像、附件、图片等。
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  });
}
