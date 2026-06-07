// lib/core/storage/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// token 单独封装，避免 token key 散落在业务代码里。
class TokenStorage {
  TokenStorage._();

  static const String _tokenKey = 'auth_token';

  // token 属于敏感数据，因此使用 flutter_secure_storage。
  // Android/iOS 会走系统安全存储能力，比 SharedPreferences 更适合保存 token。
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getToken() {
    // 安全存储 API 是异步的，所以 AuthProvider.restoreSession 必须 await。
    return _storage.read(key: _tokenKey);
  }

  static Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
