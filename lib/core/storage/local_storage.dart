// lib/core/storage/local_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/crash_reporter.dart';

// SharedPreferences 的薄封装。业务层统一用 LocalStorage，方便以后替换存储实现。
class LocalStorage {
  LocalStorage._();

  static SharedPreferences? _preferences;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    // App 启动时初始化一次，后面读写就不需要反复 await getInstance。
    try {
      _preferences = await SharedPreferences.getInstance();
      _initialized = true;
    } catch (error, stack) {
      _initialized = false;
      CrashReporter.report(error, stack);
    }
  }

  static String? getString(String key) {
    if (!_initialized) {
      return null;
    }
    return _preferences?.getString(key);
  }

  static Future<bool> setString(String key, String value) {
    if (!_initialized) {
      return Future<bool>.value(false);
    }
    return _preferences!.setString(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    if (!_initialized) {
      return defaultValue;
    }
    return _preferences?.getBool(key) ?? defaultValue;
  }

  static Future<bool> setBool(String key, bool value) {
    if (!_initialized) {
      return Future<bool>.value(false);
    }
    return _preferences!.setBool(key, value);
  }

  static Future<bool> remove(String key) {
    if (!_initialized) {
      return Future<bool>.value(false);
    }
    return _preferences!.remove(key);
  }

  static Future<bool> clear() {
    if (!_initialized) {
      return Future<bool>.value(false);
    }
    return _preferences!.clear();
  }
}
