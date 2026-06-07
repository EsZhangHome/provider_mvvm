// lib/core/network/api_response.dart
import '../config/env_config.dart';

// 后端统一响应结构。真实项目里如果字段不是 code/message/data，只需要改这里。
class ApiResponse<T> {
  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final T? data;

  // 两种成功判断模式：
  // 1. useHttpStatus=true：适合直接用 HTTP 状态码判断，200-299 表示成功。
  // 2. useHttpStatus=false：适合国内常见业务码模式，默认 code == 0 表示成功。
  bool get isSuccess {
    if (EnvConfig.useHttpStatus) {
      return code >= 200 && code < 300;
    }
    return code == EnvConfig.apiSuccessCode;
  }

  // fromJsonT 负责把 data 转成具体业务模型，比如 UserModel、Banner 列表。
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    // fromJsonT 为空时，直接把 data 当作 T 返回。
    // fromJsonT 不为空时，把 data 交给业务 Model 自己解析。
    // 这样 ApiClient 不需要知道 UserModel、HomeBanner 等具体类型。
    return ApiResponse<T>(
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: fromJsonT == null ? json['data'] as T? : fromJsonT(json['data']),
    );
  }
}
