// lib/core/storage/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// token 单独封装，避免 token key 散落在业务代码里。
class TokenStorage {
  TokenStorage._();

  static const String _tokenKey = 'auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
