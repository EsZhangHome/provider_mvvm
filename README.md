# Provider MVVM Flutter 架构说明

这是一个面向中型 Flutter 项目的可复用基础架构。项目核心技术栈：

- Flutter
- Provider
- MVVM
- Repository
- Dio
- GoRouter
- get_it
- shared_preferences
- flutter_secure_storage

项目当前只保留 Android 和 iOS 平台目录，适合作为移动端业务 App 的基础工程。

## 1. 项目整体分层

项目采用“按基础能力 + 按业务模块”组织代码：

```text
lib/
  main.dart
  app.dart

  core/        # 基础能力层：网络、路由、配置、存储、主题、工具、DI
  global/      # 全局 Provider：登录状态、主题状态
  shared/      # 跨模块复用的 Model 和 Widget
  features/    # 业务模块：login、main、home、community、mine 等
```

每一层的职责非常明确：

- `core/`：和具体业务无关，任何模块都可以复用。
- `global/`：App 级别状态，比如登录态、主题模式。
- `shared/`：多个业务模块都会用到的组件和模型。
- `features/`：具体业务功能，每个模块内部维护自己的 `model / repository / view_model / view`。

推荐后续开发继续沿用这个结构，不要把业务代码直接堆到 `main.dart`、`app.dart` 或 `core/` 中。

## 2. 启动流程

入口文件是 [lib/main.dart](lib/main.dart)。

启动顺序：

1. 注册全局异常兜底。
2. 调用 `WidgetsFlutterBinding.ensureInitialized()`。
3. 初始化本地存储 `LocalStorage.init()`。
4. 初始化依赖注入 `setupServiceLocator()`。
5. 执行 `runApp(const MyApp())`。

简化流程如下：

```text
main()
  -> FlutterError / PlatformDispatcher 异常兜底
  -> LocalStorage.init()
  -> setupServiceLocator()
  -> runApp(MyApp)
```

[lib/app.dart](lib/app.dart) 负责组装 App 外壳：

- 使用 `MultiProvider` 注入全局 Provider。
- 使用 `MaterialApp.router` 接入 GoRouter。
- 接入 light/dark 主题。
- 接入基础本地化配置。

注意：`GoRouter` 实例在 `_AppViewState` 中只创建一次，避免 App rebuild 时重复创建路由对象。

## 3. 核心目录说明

### 3.1 core/base

路径：[lib/core/base](lib/core/base)

这里放 MVVM 基础类和通用状态能力。

#### BaseViewModel

文件：[lib/core/base/base_view_model.dart](lib/core/base/base_view_model.dart)

`BaseViewModel` 是所有页面 ViewModel 的基类，继承自 `ChangeNotifier`。

它负责：

- 管理页面状态 `ViewState`
- 统一处理 loading / success / empty / error
- 防止 `dispose` 后继续 `notifyListeners`
- 提供 `asyncRequest` 包装异步请求
- 内置请求防抖，避免连续触发重复请求
- 内置 `CancelToken`，页面销毁时自动取消请求
- 识别 `BusinessException`，把业务错误文案展示给页面

页面状态定义在 [lib/core/base/view_state.dart](lib/core/base/view_state.dart)：

```dart
enum ViewState {
  idle,
  loading,
  success,
  empty,
  error,
}
```

使用方式示例：

```dart
final data = await asyncRequest(
  () => repository.fetchData(cancelToken: cancelToken),
  isEmpty: (data) => data.isEmpty,
  cancelToken: cancelToken,
);
```

#### BasePage

文件：[lib/core/base/base_page.dart](lib/core/base/base_page.dart)

`BasePage` 是页面通用容器，负责：

- 通过 `ChangeNotifierProvider(create: ...)` 创建 ViewModel
- 使用 `Consumer` 监听 ViewModel
- 根据 `ViewState` 自动展示 loading / error / empty / content
- 支持 `onModelReady`，用于页面首帧后请求数据
- 支持 `onRetry`，用于错误页重试
- 支持两种 loading 样式：
  - `LoadingStyle.replace`：loading 替换整个内容区
  - `LoadingStyle.overlay`：loading 以遮罩形式覆盖在内容上

`HomePage`、`CommunityPage`、`MinePage` 等页面都可以复用它。

#### CachePolicy

文件：[lib/core/base/cache_policy.dart](lib/core/base/cache_policy.dart)

`CachePolicy<T>` 是 Repository 层缓存抽象。

当前提供了 `MemoryCachePolicy<T>`，用于内存缓存。`HomeRepositoryImpl` 中已经做了示范：先读缓存，有缓存就先返回缓存，再后台拉取新数据并写入缓存。

适合列表页、首页数据等场景。

### 3.2 core/config

路径：[lib/core/config/env_config.dart](lib/core/config/env_config.dart)

`EnvConfig` 负责环境配置，支持通过 `--dart-define` 覆盖默认值。

目前支持：

- `apiBaseUrl`
- `connectTimeout`
- `receiveTimeout`
- `sendTimeout`
- `retryCount`
- `apiSuccessCode`
- `useHttpStatus`
- `isDebug`

默认不传参数也能正常启动。

运行示例：

```bash
flutter run \
  --dart-define=ENV_API_BASE_URL=https://dev-api.example.com \
  --dart-define=ENV_RETRY_COUNT=3
```

### 3.3 core/network

路径：[lib/core/network](lib/core/network)

网络层使用 Dio，但业务模块不直接依赖 Dio。

核心文件：

- `api_service.dart`：网络服务抽象接口
- `api_client.dart`：Dio 实现类
- `api_response.dart`：统一响应模型
- `api_exception.dart`：统一异常模型
- `dio_interceptor.dart`：Dio 拦截器
- `endpoints.dart`：接口地址集中管理

#### ApiService

文件：[lib/core/network/api_service.dart](lib/core/network/api_service.dart)

这是 Repository 依赖的网络接口，定义了：

- `get`
- `post`
- `put`
- `delete`
- `upload`

Repository 依赖 `ApiService`，不直接依赖 `ApiClient` 或 Dio。这样测试时可以传 fake 实现。

#### ApiClient

文件：[lib/core/network/api_client.dart](lib/core/network/api_client.dart)

`ApiClient implements ApiService`，是真正的 Dio 请求实现。

它负责：

- 初始化 Dio
- 使用 `EnvConfig` 设置 `baseUrl` 和超时时间
- 统一解析 `ApiResponse<T>`
- 统一转换 `DioException`
- 抛出 `BusinessException`
- 接入 token 拦截器、日志拦截器、401 拦截器、重试拦截器
- 支持文件上传预留接口

#### ApiResponse

文件：[lib/core/network/api_response.dart](lib/core/network/api_response.dart)

后端统一响应结构：

```dart
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
}
```

`isSuccess` 支持两种模式：

- `EnvConfig.useHttpStatus == true`：HTTP 状态码 200-299 表示成功
- `EnvConfig.useHttpStatus == false`：业务码模式，默认 `code == 0` 表示成功

国内很多后端会返回：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

当前默认就是兼容这种业务码模式。

#### ApiException / BusinessException

文件：[lib/core/network/api_exception.dart](lib/core/network/api_exception.dart)

`ApiException` 表示通用网络异常，比如：

- 网络连接异常
- 请求超时
- 请求取消
- 服务器错误
- 未知错误

`BusinessException` 表示业务异常，比如：

- 余额不足
- 账号被冻结
- 用户无权限

`BaseViewModel.asyncRequest` 会识别 `BusinessException`，优先展示 `userMessage`。

#### Dio 拦截器

文件：[lib/core/network/dio_interceptor.dart](lib/core/network/dio_interceptor.dart)

当前有 4 类拦截器：

- `TokenInterceptor`：请求前自动添加 `Authorization: Bearer token`
- `AppLogInterceptor`：debug 模式打印请求、响应和错误
- `UnauthorizedInterceptor`：遇到 401 时通知 `AuthProvider.logout`
- `RetryInterceptor`：连接异常或超时自动重试

401 处理有并发保护：多个接口同时返回 401 时，只会触发一次退出登录，避免重复跳转。

### 3.4 core/router

路径：[lib/core/router](lib/core/router)

路由使用 GoRouter。

核心文件：

- `route_paths.dart`：路由路径常量
- `app_router.dart`：GoRouter 配置
- `route_guard.dart`：路由守卫抽象

当前路由：

```text
/login
/main
/main/home
/main/community
/main/mine
```

登录拦截规则：

- 未登录访问 `/main`、`/main/home`、`/main/community`、`/main/mine`，跳转 `/login`
- 已登录访问 `/login`，跳转 `/main`
- 未匹配路由展示 `NotFoundView`

路由守卫被抽成 `RouteGuard`，后续如果要加会员守卫、权限守卫、灰度守卫，可以继续新增实现类，然后传入 `AppRouter`。

### 3.5 core/storage

路径：[lib/core/storage](lib/core/storage)

#### LocalStorage

文件：[lib/core/storage/local_storage.dart](lib/core/storage/local_storage.dart)

对 `SharedPreferences` 做了一层封装。

业务代码不要直接使用 `SharedPreferences`，统一通过 `LocalStorage` 访问。

它支持初始化失败降级：如果 `SharedPreferences` 初始化失败，App 仍然可以启动，读写方法会安全返回默认值或 `false`。

#### TokenStorage

文件：[lib/core/storage/token_storage.dart](lib/core/storage/token_storage.dart)

token 使用 `flutter_secure_storage` 存储，不再明文存入 `SharedPreferences`。

注意：`getToken()` 是异步方法，调用时必须 `await`。

### 3.6 core/di

路径：[lib/core/di/service_locator.dart](lib/core/di/service_locator.dart)

依赖注入使用 `get_it`。

当前注册了：

- `ApiService`
- `HomeRepository`
- `LoginRepository`
- `ProfileRepository`
- `HomeViewModel`
- `LoginViewModel`
- `ProfileViewModel`

页面中不要再手动 new 这些对象，推荐使用：

```dart
create: () => locator<HomeViewModel>()
```

全局 Provider 目前仍由 Provider 管理，不迁移到 get_it：

- `AuthProvider`
- `ThemeProvider`

### 3.7 core/l10n

路径：[lib/core/l10n/app_strings.dart](lib/core/l10n/app_strings.dart)

当前没有引入 arb 文件，而是先用 `AppStrings` 集中管理文案。

这样做的好处是：

- 页面里不再散落中文字符串
- 后续接正式多语言时更容易迁移
- 统一修改文案更方便

### 3.8 core/theme

路径：[lib/core/theme](lib/core/theme)

包含：

- `app_theme.dart`：light / dark 主题
- `app_spacing.dart`：统一间距常量
- `app_radius.dart`：统一圆角常量

后续新增页面时，不建议直接写大量魔法数字，比如 `16`、`24`，优先使用：

```dart
AppSpacing.lg
AppSpacing.xl
AppRadius.card
```

### 3.9 core/utils

路径：[lib/core/utils](lib/core/utils)

包含：

- `logger.dart`：debug 日志
- `crash_reporter.dart`：全局异常上报入口
- `json_helper.dart`：JSON 类型转换工具

`CrashReporter` 当前只打印日志，后续接入 Sentry、Bugly 等平台时，可以直接在这里扩展。

## 4. global 层

路径：[lib/global](lib/global)

### AuthProvider

文件：[lib/global/auth_provider.dart](lib/global/auth_provider.dart)

负责全局登录态：

- 保存 token
- 保存当前用户
- App 启动时恢复登录状态
- 登录成功后保存 token 和用户
- 退出登录时清空状态
- 给 ApiClient 提供 token
- 处理 401 自动退出登录

判断是否登录：

```dart
authProvider.isLoggedIn
```

### ThemeProvider

文件：[lib/global/theme_provider.dart](lib/global/theme_provider.dart)

负责主题：

- light / dark 切换
- 保存用户主题选择
- 缓存 `ThemeData`，避免 getter 每次都重新创建主题对象

## 5. shared 层

路径：[lib/shared](lib/shared)

### shared/models

当前有：

- `UserModel`

`UserModel` 已支持：

- `fromJson`
- `toJson`
- `copyWith`
- `==`
- `hashCode`

### shared/widgets

通用状态组件：

- `LoadingView`
- `ErrorView`
- `EmptyView`
- `StateView`
- `NotFoundView`

页面状态展示由 `StateView` 统一管理，一般业务页面不需要自己写 loading / error / empty 判断。

## 6. features 业务模块

路径：[lib/features](lib/features)

当前已有模块：

```text
features/
  login/
  main/
  home/
  community/
  mine/
  profile/
```

### 6.1 login 模块

路径：[lib/features/login](lib/features/login)

职责：登录页面和登录业务。

结构：

```text
login/
  model/
    login_request.dart
    login_response.dart
  repository/
    login_repository.dart
  view_model/
    login_view_model.dart
  view/
    login_page.dart
```

数据流：

```text
LoginPage
  -> LoginViewModel.login()
  -> LoginRepository.login()
  -> 登录成功后 AuthProvider.loginSuccess()
  -> GoRouter 跳转 /main
```

`LoginPage` 使用 `BasePage<LoginViewModel>`，loading 样式是 `LoadingStyle.overlay`。

### 6.2 main 模块

路径：[lib/features/main](lib/features/main)

职责：登录后的主框架页面。

`MainPage` 使用：

- `Scaffold`
- `IndexedStack`
- `BottomNavigationBar`

三个 Tab：

- 首页：`HomePage`
- 社区：`CommunityPage`
- 我的：`MinePage`

`IndexedStack` 可以保留三个 Tab 的状态，避免切换 Tab 时：

- 页面重复创建
- 滚动位置丢失
- 接口重复请求

`MainViewModel` 只负责 `tabIndex`，不要往里面放首页、社区、我的业务数据。

### 6.3 home 模块

路径：[lib/features/home](lib/features/home)

职责：首页数据展示。

结构：

```text
home/
  model/
    home_banner.dart
  repository/
    home_repository.dart
  view_model/
    home_view_model.dart
  view/
    home_page.dart
```

`HomeRepositoryImpl` 已示范 Repository 内存缓存：

```text
fetchBanners()
  -> 先 readCache()
  -> 有缓存：立即返回缓存，并后台拉新数据
  -> 无缓存：请求远端数据，再 writeCache()
```

当前没有真实后端，所以用 `Future.delayed` 模拟接口数据；真实接入时替换 Repository 中注释的 `_apiService.get` 即可。

### 6.4 community 模块

路径：[lib/features/community](lib/features/community)

职责：社区 Tab。

当前包含：

- `CommunityPage`
- `CommunityViewModel`

目前使用模拟帖子数据。后续如果社区接口复杂，可以新增：

```text
community/
  model/
  repository/
```

### 6.5 mine 模块

路径：[lib/features/mine](lib/features/mine)

职责：我的 Tab。

当前包含：

- 展示当前用户信息
- 退出登录

退出登录流程：

```text
MinePage
  -> AuthProvider.logout()
  -> 清空 token 和用户信息
  -> GoRouter 跳转 /login
```

### 6.6 profile 模块

路径：[lib/features/profile](lib/features/profile)

这是早期个人中心模块，目前主 Tab 已使用 `MinePage`。`ProfileRepository` 和 `ProfileViewModel` 仍保留在工程中，方便后续需要独立个人资料页时复用。

## 7. MVVM + Repository 数据流

项目推荐的数据流：

```text
View
  -> ViewModel
  -> Repository
  -> ApiService
  -> ApiClient(Dio)
```

反向更新：

```text
ApiClient 返回数据
  -> Repository 转换成 Model
  -> ViewModel 保存页面字段并切换 ViewState
  -> notifyListeners()
  -> View 通过 Consumer / BasePage 刷新 UI
```

各层职责：

### View

只负责：

- 画 UI
- 收集用户输入
- 响应点击事件
- 调用 ViewModel 方法
- 做页面跳转

不要在 View 中直接调用 Dio 或 Repository。

### ViewModel

负责：

- 页面状态
- 页面业务逻辑
- 调用 Repository
- 暴露页面需要的数据字段
- 调用 `setLoading / setSuccess / setEmpty / setError`

不要在 ViewModel 中直接创建 Dio。

### Repository

负责：

- 请求数据
- 转换数据
- 管理数据来源
- 可选缓存策略

不要在 Repository 中依赖 `BuildContext`，也不要处理 UI 状态。

### ApiClient

负责：

- 真实网络请求
- 拦截器
- token
- 统一响应解析
- 统一异常转换

## 8. 新增业务模块应该怎么做

假设要新增 `order` 模块，推荐步骤：

### 1. 创建目录

```text
lib/features/order/
  model/
    order_model.dart
  repository/
    order_repository.dart
  view_model/
    order_view_model.dart
  view/
    order_page.dart
```

### 2. 定义 Model

```dart
class OrderModel {
  const OrderModel({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: asOr(json['id'], ''),
      title: asOr(json['title'], ''),
    );
  }
}
```

### 3. 定义 Repository 接口和实现

```dart
abstract class OrderRepository {
  Future<List<OrderModel>> fetchOrders({CancelToken? cancelToken});
}

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiClient.instance;

  final ApiService _apiService;

  @override
  Future<List<OrderModel>> fetchOrders({CancelToken? cancelToken}) async {
    final response = await _apiService.get<List<OrderModel>>(
      '/orders',
      cancelToken: cancelToken,
      fromJson: (json) => asList(
        json,
        OrderModel.fromJson,
      ),
    );
    return response.data ?? [];
  }
}
```

### 4. 定义 ViewModel

```dart
class OrderViewModel extends BaseViewModel {
  OrderViewModel(this._repository);

  final OrderRepository _repository;
  List<OrderModel> orderList = [];

  Future<void> loadOrders() async {
    final data = await asyncRequest<List<OrderModel>>(
      () => _repository.fetchOrders(cancelToken: cancelToken),
      isEmpty: (data) => data.isEmpty,
      cancelToken: cancelToken,
    );

    if (data != null) {
      orderList = data;
      safeNotifyListeners();
    }
  }
}
```

### 5. 定义 Page

```dart
class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage<OrderViewModel>(
      create: () => locator<OrderViewModel>(),
      onModelReady: (viewModel) => viewModel.loadOrders(),
      onRetry: (viewModel) => viewModel.loadOrders(),
      builder: (context, viewModel) {
        return ListView.builder(
          itemCount: viewModel.orderList.length,
          itemBuilder: (context, index) {
            return Text(viewModel.orderList[index].title);
          },
        );
      },
    );
  }
}
```

### 6. 注册依赖

在 [lib/core/di/service_locator.dart](lib/core/di/service_locator.dart) 中注册：

```dart
locator.registerLazySingleton<OrderRepository>(
  () => OrderRepositoryImpl(apiService: locator()),
);

locator.registerFactory<OrderViewModel>(
  () => OrderViewModel(locator()),
);
```

### 7. 增加路由

在 `RoutePaths` 中增加路径，再到 `AppRouter` 中增加 `GoRoute`。

## 9. 接入真实后端需要改哪里

### 1. 修改 baseUrl

推荐通过 `--dart-define`：

```bash
flutter run --dart-define=ENV_API_BASE_URL=https://api.your-domain.com
```

也可以修改 [lib/core/config/env_config.dart](lib/core/config/env_config.dart) 的默认值。

### 2. 修改接口路径

在 [lib/core/network/endpoints.dart](lib/core/network/endpoints.dart) 中集中维护接口路径。

### 3. 替换 Repository 的模拟数据

比如 `HomeRepositoryImpl` 中现在使用 `Future.delayed` 模拟接口。接真实后端时，把模拟数据替换成 `_apiService.get / post`。

### 4. 确认响应结构

如果后端响应不是：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

需要修改 [lib/core/network/api_response.dart](lib/core/network/api_response.dart)。

### 5. 确认成功码

默认业务成功码是 `0`。

如果后端是 HTTP 状态码模式，可以启动时传：

```bash
flutter run --dart-define=ENV_USE_HTTP_STATUS=true
```

如果后端业务成功码不是 0，可以传：

```bash
flutter run --dart-define=ENV_API_SUCCESS_CODE=200
```

## 10. 常用命令

安装依赖：

```bash
flutter pub get
```

静态检查：

```bash
flutter analyze
```

运行测试：

```bash
flutter test
```

运行 App：

```bash
flutter run
```

指定环境运行：

```bash
flutter run \
  --dart-define=ENV_API_BASE_URL=https://dev-api.example.com \
  --dart-define=ENV_RETRY_COUNT=2
```

## 11. 开发约定

为了让项目长期保持清晰，请遵守这些约定：

- View 不直接调用 Dio。
- View 不直接调用 Repository。
- ViewModel 不直接创建 Dio。
- Repository 不依赖 `BuildContext`。
- 全局状态放 `global/`。
- 业务状态放各自模块的 ViewModel。
- 通用能力放 `core/`。
- 跨模块复用组件放 `shared/`。
- 新业务模块优先按 `model / repository / view_model / view` 拆分。
- 页面 loading / error / empty 优先使用 `BasePage` 和 `StateView`。
- 字符串优先放到 `AppStrings`。
- 间距优先使用 `AppSpacing`。
- 圆角优先使用 `AppRadius`。
- ViewModel 和 Repository 优先通过 `get_it` 注册和获取。

## 12. 一句话理解这个架构

这个项目的核心思想是：

```text
Provider 管全局状态和页面刷新，
ViewModel 管页面状态和业务流程，
Repository 管数据来源和数据转换，
ApiClient 管网络请求和异常处理，
GoRouter 管声明式路由和登录拦截。
```

只要后续开发遵守这个数据流，项目规模变大后依然能保持清晰、可测试、可维护。
