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
  if (locator.isRegistered<ApiService>()) {
    return;
  }

  locator.registerLazySingleton<ApiService>(() => ApiClient.instance);
  locator.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(apiService: locator()),
  );
  locator.registerLazySingleton<LoginRepository>(
    () => LoginRepositoryImpl(apiService: locator()),
  );
  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(apiService: locator()),
  );
  locator.registerFactory<HomeViewModel>(() => HomeViewModel(locator()));
  locator.registerFactory<LoginViewModel>(() => LoginViewModel(locator()));
  locator.registerFactory<ProfileViewModel>(() => ProfileViewModel(locator()));
}
