// lib/core/di/service_locator.dart
//
// 作用：依赖注入容器，管理所有 Repository、ViewModel、ApiService 的创建和生命周期。
//
// 使用 get_it 作为 DI 容器，提供以下注册方式：
// 1. registerLazySingleton：懒加载单例，第一次获取时创建，后续返回同一实例
//    - 适合：ApiService（全局唯一）、Repository（无页面状态，可复用）
// 2. registerFactory：每次获取都创建新实例
//    - 适合：ViewModel（每个页面需要独立的实例和状态）
//
// 注册顺序：
// 先注册底层依赖（ApiService、DatabaseService），再注册上层依赖（Repository、ViewModel），
// 因为上层依赖需要从容器中获取底层依赖。
//
// 使用方式：
// ```dart
// // 在页面中获取 ViewModel
// final viewModel = locator<HomeViewModel>();
//
// // 在 Repository 中获取 ApiService / DatabaseService
// final apiService = locator<ApiService>();
// ```
//
// 为什么不直接 new：
// 1. 解耦：页面不需要知道 HomeViewModel 需要 HomeRepository 作为参数
// 2. 测试：可以替换实现（如用 FakeApiService 替换 ApiClient）
// 3. 生命周期管理：容器统一管理 LazySingleton 和 Factory 的创建

import 'package:get_it/get_it.dart';

import '../../features/home/repository/home_repository.dart';
import '../../features/home/view_model/home_view_model.dart';
import '../../features/login/repository/login_repository.dart';
import '../../features/login/view_model/login_view_model.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/profile/view_model/profile_view_model.dart';
import '../database/database_service.dart';
import '../database/sqlite_database_service.dart';
import '../network/api_client.dart';
import '../network/api_service.dart';

/// 全局 get_it 实例，可在 App 任何地方通过 locator<T>() 获取依赖。
///
/// 注意：不要在 build 方法中频繁调用 locator<T>()，
/// 应该在 initState 或 create 回调中获取并保存引用。
final GetIt locator = GetIt.instance;

/// 注册所有依赖。
///
/// 在 main.dart 中，WidgetsFlutterBinding.ensureInitialized() 之后调用。
///
/// 防重复注册：每个依赖注册前都会先判断是否已经注册。
///
/// 这样测试可以只替换某一层 fake，例如提前注册 FakeApiService，
/// 再调用 setupServiceLocator() 注册其他默认依赖。
///
/// 注册顺序：
/// 1. ApiService、DatabaseService（底层服务）
/// 2. Repository（数据仓库层，依赖 ApiService）
/// 3. ViewModel（页面状态管理，依赖 Repository）
Future<void> setupServiceLocator() async {
  // ---- 第 1 层：网络服务 ----
  // ApiClient 是全局单例，整个 App 只有一个实例
  // 所有 Repository 共享同一个 ApiClient，共享拦截器、token 等配置
  if (!locator.isRegistered<ApiService>()) {
    locator.registerLazySingleton<ApiService>(() => ApiClient.instance);
  }

  // ---- 第 1 层：数据库服务 ----
  // DatabaseService 是本地数据库抽象，默认实现使用 sqflite
  // Repository 依赖 DatabaseService，而不是直接依赖 sqflite，方便后续测试替换
  if (!locator.isRegistered<DatabaseService>()) {
    locator.registerLazySingleton<DatabaseService>(SqliteDatabaseService.new);
  }

  // ---- 第 2 层：数据仓库 ----
  // Repository 不保存页面状态，可以作为 lazySingleton 复用
  // 它们从 locator 中获取 ApiService，不需要手动传入
  //
  // 如果某个 Repository 未来有用户隔离的缓存需求，
  // 可以改为 registerFactory，每次创建新实例
  if (!locator.isRegistered<HomeRepository>()) {
    locator.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(apiService: locator()),
    );
  }
  if (!locator.isRegistered<LoginRepository>()) {
    locator.registerLazySingleton<LoginRepository>(
      () => LoginRepositoryImpl(apiService: locator()),
    );
  }
  if (!locator.isRegistered<ProfileRepository>()) {
    locator.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(apiService: locator()),
    );
  }

  // ---- 第 3 层：ViewModel ----
  // ViewModel 持有页面状态，必须每次页面创建时生成新实例
  // 所以使用 registerFactory 而不是 registerLazySingleton
  // 如果使用 LazySingleton，多个页面会共享同一个 ViewModel，导致状态混乱
  if (!locator.isRegistered<HomeViewModel>()) {
    locator.registerFactory<HomeViewModel>(() => HomeViewModel(locator()));
  }
  if (!locator.isRegistered<LoginViewModel>()) {
    locator.registerFactory<LoginViewModel>(() => LoginViewModel(locator()));
  }
  if (!locator.isRegistered<ProfileViewModel>()) {
    locator
        .registerFactory<ProfileViewModel>(() => ProfileViewModel(locator()));
  }
}
