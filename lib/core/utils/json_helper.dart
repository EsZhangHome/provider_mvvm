// lib/core/utils/json_helper.dart

T? asOrNull<T>(dynamic value) {
  // 类型匹配就返回，否则返回 null。
  // 用来替代 json['xxx'] as String? 这类散落写法。
  return value is T ? value : null;
}

T asOr<T>(dynamic value, T defaultValue) {
  // 类型匹配就返回，否则返回默认值。
  // 适合字符串、数字、布尔值等基础字段解析。
  return value is T ? value : defaultValue;
}

List<T> asList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) {
    // 后端字段不是 List 时，按空列表处理，避免页面崩溃。
    return [];
  }
  // 只转换 Map<String, dynamic> 元素，过滤掉异常结构。
  return value
      .whereType<Map<String, dynamic>>()
      .map<T>(fromJson)
      .toList(growable: false);
}
