// lib/core/base/cache_policy.dart

// Repository 层通用缓存接口，具体缓存可以是内存、数据库或文件。
abstract class CachePolicy<T> {
  Future<T?> readCache();
  Future<void> writeCache(T data);
  Future<void> clearCache();
}

// 简单内存缓存。适合列表页做“先显示旧数据，再拉新数据”的基础示范。
class MemoryCachePolicy<T> implements CachePolicy<T> {
  MemoryCachePolicy({required this.duration});

  final Duration duration;
  T? _data;
  DateTime? _cachedAt;

  @override
  Future<T?> readCache() async {
    final cachedAt = _cachedAt;
    if (_data == null || cachedAt == null) {
      return null;
    }
    if (DateTime.now().difference(cachedAt) > duration) {
      await clearCache();
      return null;
    }
    return _data;
  }

  @override
  Future<void> writeCache(T data) async {
    _data = data;
    _cachedAt = DateTime.now();
  }

  @override
  Future<void> clearCache() async {
    _data = null;
    _cachedAt = null;
  }
}
