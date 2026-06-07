// lib/core/base/cache_policy.dart

// Repository 层通用缓存接口，具体缓存可以是内存、数据库或文件。
abstract class CachePolicy<T> {
  // 读取缓存。没有缓存或缓存过期时返回 null。
  Future<T?> readCache();

  // 写入缓存。具体实现可以决定写入内存、文件或数据库。
  Future<void> writeCache(T data);

  // 清理缓存。适合退出登录、手动刷新、缓存过期等场景。
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
      // 从未写入过缓存。
      return null;
    }
    if (DateTime.now().difference(cachedAt) > duration) {
      // 超过有效期后主动清空，避免下一次继续读到旧数据。
      await clearCache();
      return null;
    }
    // 缓存仍在有效期内，直接返回。
    return _data;
  }

  @override
  Future<void> writeCache(T data) async {
    // 写数据的同时记录写入时间，用于后续判断是否过期。
    _data = data;
    _cachedAt = DateTime.now();
  }

  @override
  Future<void> clearCache() async {
    // 内存缓存不需要额外释放资源，清空引用即可。
    _data = null;
    _cachedAt = null;
  }
}
