// lib/core/utils/json_helper.dart

T? asOrNull<T>(dynamic value) {
  return value is T ? value : null;
}

T asOr<T>(dynamic value, T defaultValue) {
  return value is T ? value : defaultValue;
}

List<T> asList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) {
    return [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map<T>(fromJson)
      .toList(growable: false);
}
