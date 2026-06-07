// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';

import '../../features/home/repository/home_repository.dart';
import '../../features/home/view_model/home_view_model.dart';
import '../../features/login/repository/login_repository.dart';
import '../../features/login/view_model/login_view_model.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/profile/view_model/profile_view_model.dart';
import '../network/api_client.dart';
import '../network/api_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 防重复注册。测试或热重启场景下可能多次调用 setupServiceLocator。
  if (locator.isRegistered<ApiService>()) {
    return;
  }

  // ApiService 是网络入口，全局只需要一个 ApiClient 单例。
  locator.registerLazySingleton<ApiService>(() => ApiClient.instance);

  // Repository 一般不保存页面状态，可以作为 lazySingleton 复用。
  // 如果某个 Repository 未来有用户隔离缓存，也可以改成 factory。
  locator.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(apiService: locator()),
  );
  locator.registerLazySingleton<LoginRepository>(
    () => LoginRepositoryImpl(apiService: locator()),
  );
  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(apiService: locator()),
  );

  // ViewModel 是页面状态，必须每次页面创建时生成新实例。
  // 所以这里使用 registerFactory，而不是 registerLazySingleton。
  locator.registerFactory<HomeViewModel>(() => HomeViewModel(locator()));
  locator.registerFactory<LoginViewModel>(() => LoginViewModel(locator()));
  locator.registerFactory<ProfileViewModel>(() => ProfileViewModel(locator()));
}
