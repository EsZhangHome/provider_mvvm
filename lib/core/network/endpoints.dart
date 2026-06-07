// lib/core/network/endpoints.dart
import '../config/env_config.dart';

// 所有接口地址集中放这里，换后端环境时不用到处找字符串。
class Endpoints {
  const Endpoints._();

  static const String baseUrl = EnvConfig.apiBaseUrl;
  static const String login = '/auth/login';
  static const String homeBanners = '/home/banners';
  static const String profile = '/user/profile';
}
