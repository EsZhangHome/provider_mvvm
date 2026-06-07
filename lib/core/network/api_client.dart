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
    // 这些值来自 EnvConfig，所以可以通过 --dart-define 切换不同环境。
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

  // Dio 实例只在 ApiClient 内部维护。
  // 外部如果要请求接口，优先通过 ApiService 的 get/post/put/delete/upload 方法。
  late final Dio _dio;

  // tokenProvider 由 AuthProvider 注入。
  // 这样网络层不用直接依赖 AuthProvider，也就不会和 global 层产生强耦合。
  String? Function()? _tokenProvider;

  // 401 回调由 AuthProvider 注入。
  // 当前逻辑是 token 失效时退出登录，后续也可以改成刷新 token。
  void Function()? _onUnauthorized;

  // 防止多个并发 401 重复触发 logout。
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
    // GET 通常用于列表、详情等读取类接口。
    // fromJson 用于把 response.data 转成具体业务类型。
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
    // POST 通常用于登录、创建资源、提交表单等写入类接口。
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
    // PUT 通常用于完整更新资源。
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
    // DELETE 通常用于删除资源，也保留 data/queryParameters 以兼容不同后端风格。
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
    // 上传时先把普通字段和文件字段组装成 FormData。
    // fileField 默认叫 file，如果后端字段名不同，可以调用时传入。
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
      // 真正执行 Dio 请求。调用方传入的是一个闭包，
      // 这样 get/post/put/delete/upload 都能共用同一套解析和异常处理逻辑。
      final response = await request();
      final data = response.data;
      // 如果后端返回标准 Map，就按 ApiResponse<T> 解析。
      if (data is Map<String, dynamic>) {
        final apiResponse = ApiResponse<T>.fromJson(data, fromJson);
        if (!apiResponse.isSuccess) {
          // HTTP 请求成功但业务 code 失败，属于业务异常。
          // 例如：账号被冻结、余额不足、权限不够。
          throw BusinessException(
            code: apiResponse.code,
            userMessage: apiResponse.message,
          );
        }
        return apiResponse;
      }
      // 有些接口可能直接返回数组或字符串，这里也给一个兼容出口。
      // 这种情况下 code 使用 HTTP statusCode，message 使用 statusMessage。
      return ApiResponse<T>(
        code: response.statusCode ?? 200,
        message: response.statusMessage ?? 'success',
        data: fromJson == null ? data as T? : fromJson(data),
      );
    } on DioException catch (error) {
      // DioException 类型很多，统一转换为 ApiException，
      // ViewModel 层就不需要知道 Dio 的内部错误枚举。
      throw ApiException.fromDioException(error);
    }
  }

  void _resetInterceptors() {
    // 每次 tokenProvider 或 401 回调变更后，重新组装拦截器链。
    // 拦截器顺序很重要：
    // 1. TokenInterceptor 先给请求加 token
    // 2. AppLogInterceptor 打印请求和响应
    // 3. UnauthorizedInterceptor 处理 401
    // 4. RetryInterceptor 放最后，方便捕获前面传下来的网络错误并重试
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
