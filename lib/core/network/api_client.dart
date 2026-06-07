// lib/core/network/api_client.dart
import 'package:dio/dio.dart';

import '../config/env_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'api_service.dart';
import 'dio_interceptor.dart';
import 'endpoints.dart';

// ApiClient 是网络请求统一入口。Repository 只依赖它，不直接创建 Dio。
class ApiClient implements ApiService {
  ApiClient._internal() {
    // Dio 基础配置集中在这里：baseUrl、超时、公共 headers。
    _dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: EnvConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: EnvConfig.receiveTimeout),
        sendTimeout: const Duration(seconds: EnvConfig.sendTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _resetInterceptors();
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  String? Function()? _tokenProvider;
  void Function()? _onUnauthorized;
  UnauthorizedGuard? _unauthorizedGuard;

  Dio get dio => _dio;

  // AuthProvider 登录成功后提供 token，拦截器会自动读取。
  void setTokenProvider(String? Function() tokenProvider) {
    _tokenProvider = tokenProvider;
    _resetInterceptors();
  }

  // 401 时的回调由外部注入，避免网络层直接依赖 AuthProvider。
  void setUnauthorizedCallback(void Function() callback) {
    _onUnauthorized = callback;
    _unauthorizedGuard = UnauthorizedGuard(onUnauthorized: callback);
    _resetInterceptors();
  }

  // 新登录会话开始后重置 401 防抖，避免上一次会话的 401 状态影响下一次。
  void resetUnauthorizedGuard() {
    _unauthorizedGuard?.reset();
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) {
    return _request<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) {
    return _request<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) {
    return _request<T>(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) {
    return _request<T>(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  // 文件上传预留接口。后续上传头像、附件时可以直接复用。
  @override
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) async {
    final formData = FormData.fromMap({
      ...?data,
      fileField: await MultipartFile.fromFile(filePath),
    });
    return _request<T>(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJson,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      // 如果后端返回标准 Map，就按 ApiResponse<T> 解析。
      if (data is Map<String, dynamic>) {
        final apiResponse = ApiResponse<T>.fromJson(data, fromJson);
        if (!apiResponse.isSuccess) {
          throw BusinessException(
            code: apiResponse.code,
            userMessage: apiResponse.message,
          );
        }
        return apiResponse;
      }
      // 有些接口可能直接返回数组或字符串，这里也给一个兼容出口。
      return ApiResponse<T>(
        code: response.statusCode ?? 200,
        message: response.statusMessage ?? 'success',
        data: fromJson == null ? data as T? : fromJson(data),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  void _resetInterceptors() {
    // 每次 tokenProvider 或 401 回调变更后，重新组装拦截器链。
    _dio.interceptors.clear();
    _dio.interceptors
        .add(TokenInterceptor(tokenProvider: () => _tokenProvider?.call()));
    _dio.interceptors.add(AppLogInterceptor());
    if (_onUnauthorized != null) {
      _unauthorizedGuard ??=
          UnauthorizedGuard(onUnauthorized: _onUnauthorized!);
      _dio.interceptors
          .add(UnauthorizedInterceptor(guard: _unauthorizedGuard!));
    }
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }
}
