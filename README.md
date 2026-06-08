# Provider MVVM Flutter 架构说明

这是一个面向中型 Flutter 项目的可复用基础架构。项目核心技术栈：

- Flutter
- Provider
- MVVM
- Repository
- Dio
- GoRouter
- get_it
- sqflite
- shared_preferences
- flutter_secure_storage

项目当前只保留 Android 和 iOS 平台目录，适合作为移动端业务 App 的基础工程。

## 1. 项目整体分层

项目采用“按基础能力 + 按业务模块”组织代码：

```text
lib/
  main.dart
  app.dart

  core/        # 基础能力层：网络、数据库、路由、配置、存储、主题、工具、DI
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
4. 初始化本地数据库 `AppDatabase.init()`。
5. 初始化依赖注入 `setupServiceLocator()`。
6. 执行 `runApp(const MyApp())`。

简化流程如下：

```text
main()
  -> FlutterError / PlatformDispatcher 异常兜底
  -> LocalStorage.init()
  -> AppDatabase.init()
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
- `enableCharlesProxy`
- `charlesProxyHost`
- `charlesProxyPort`
- `allowCharlesBadCertificate`
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

#### Charles 抓包怎么用

项目已经把 Charles 代理开关接进了 `EnvConfig` 和 `ApiClient`。

默认情况下不会走 Charles，只有启动 App 时显式传入 `ENV_ENABLE_CHARLES_PROXY=true`，Dio 请求才会被转发到 Charles。

##### 1. 先确认 Charles 代理端口

打开 Charles：

1. 进入 `Proxy` -> `Proxy Settings...`
2. 确认 `HTTP Proxy` 已开启
3. 记住端口号，Charles 默认是 `8888`

如果你没有改过 Charles 配置，端口一般不用动。

##### 2. 确认 Flutter 要连接的代理地址

不同运行环境填写的 host 不一样：

| 运行环境 | `ENV_CHARLES_PROXY_HOST` 建议值 |
| --- | --- |
| iOS 模拟器 | `127.0.0.1` 或电脑局域网 IP |
| Android 模拟器 | `10.0.2.2` |
| iPhone / Android 真机 | 电脑在当前 Wi-Fi 下的局域网 IP |

电脑局域网 IP 可以在系统网络设置里查看。真机和电脑需要连同一个 Wi-Fi。

##### 3. 启动 App 时打开 Charles 代理

iOS 模拟器常用写法：

```bash
flutter run \
  --dart-define=ENV_ENABLE_CHARLES_PROXY=true \
  --dart-define=ENV_CHARLES_PROXY_HOST=127.0.0.1 \
  --dart-define=ENV_CHARLES_PROXY_PORT=8888
```

Android 模拟器常用写法：

```bash
flutter run \
  --dart-define=ENV_ENABLE_CHARLES_PROXY=true \
  --dart-define=ENV_CHARLES_PROXY_HOST=10.0.2.2 \
  --dart-define=ENV_CHARLES_PROXY_PORT=8888
```

真机常用写法，把 `192.168.1.10` 换成你自己电脑的局域网 IP：

```bash
flutter run \
  --dart-define=ENV_ENABLE_CHARLES_PROXY=true \
  --dart-define=ENV_CHARLES_PROXY_HOST=192.168.1.10 \
  --dart-define=ENV_CHARLES_PROXY_PORT=8888
```

##### 4. 在 Charles 中允许设备连接

第一次连接时，Charles 可能会弹出是否允许该设备访问代理。

选择 `Allow` 后，请求才会出现在 Charles 的会话列表里。

如果没有弹窗，可以检查：

- App 是否真的传了 `ENV_ENABLE_CHARLES_PROXY=true`
- host 是否填对
- Charles 的 `Proxy` -> `macOS Proxy` 不影响这里，项目使用的是 Dio 自己的代理配置
- 手机和电脑是否在同一个网络

##### 5. 抓 HTTPS 接口

如果接口是 HTTPS，通常还需要安装并信任 Charles 根证书：

1. 在 Charles 中进入 `Help` -> `SSL Proxying` -> `Install Charles Root Certificate`
2. 按 Charles 提示安装证书
3. 在设备或模拟器中信任该证书
4. 在 Charles 中进入 `Proxy` -> `SSL Proxying Settings...`
5. 添加需要抓包的域名，比如 `api.example.com:443`

如果只是临时调试证书问题，也可以打开证书跳过开关：

```bash
flutter run \
  --dart-define=ENV_ENABLE_CHARLES_PROXY=true \
  --dart-define=ENV_CHARLES_PROXY_HOST=127.0.0.1 \
  --dart-define=ENV_CHARLES_PROXY_PORT=8888 \
  --dart-define=ENV_ALLOW_CHARLES_BAD_CERTIFICATE=true
```

这个开关只建议本地临时使用，发布包不要开启。

##### 6. 关闭 Charles 代理

不传 `ENV_ENABLE_CHARLES_PROXY`，或者显式传 `false` 即可关闭：

```bash
flutter run --dart-define=ENV_ENABLE_CHARLES_PROXY=false
```

关闭后 Dio 会恢复正常直连，不再经过 Charles。

### 3.3 core/database

路径：[lib/core/database](lib/core/database)

数据库层使用 `sqflite`，主要负责 App 本地 SQLite 数据库能力。

这里要先分清三种本地存储：

- `SharedPreferences`：适合保存主题、简单开关、小字符串。
- `flutter_secure_storage`：适合保存 token 这类敏感信息。
- `sqflite`：适合保存列表缓存、离线数据、结构化数据。

不要把所有本地数据都塞进 `SharedPreferences`。一旦数据有表结构、查询条件、分页缓存、离线读取需求，就应该放到数据库层。

#### 为什么选择 sqflite

这个项目选择 `sqflite` 作为默认数据库方案。

原因是：

- 使用人数多，Android/iOS 适配成熟。
- 接入成本低，新人容易理解。
- 和当前 `Repository + get_it` 架构很容易组合。
- 不需要代码生成，适合作为通用项目骨架。

如果以后项目出现非常复杂的关联查询、强类型 SQL、响应式数据库监听，可以再评估 `drift`。当前骨架优先保持简单、稳定、容易上手。

#### 数据库目录说明

核心文件：

- `app_database.dart`：数据库初始化入口，负责打开数据库文件。
- `database_service.dart`：数据库能力抽象接口，Repository 只依赖它。
- `sqlite_database_service.dart`：`DatabaseService` 的 sqflite 实现。
- `database_tables.dart`：表名、字段名集中管理。
- `database_migrations.dart`：建表和版本升级脚本。
- `database_exception.dart`：数据库异常封装。

这几个文件的关系是：

```text
main.dart
  -> AppDatabase.init()
  -> 打开 SQLite 数据库
  -> 执行 DatabaseMigrations

service_locator.dart
  -> 注册 DatabaseService
  -> 默认实现 SqliteDatabaseService

Repository
  -> 依赖 DatabaseService
  -> 不直接 import sqflite
```

#### 数据流应该怎么走

数据库不要直接给页面用。

正确的数据流：

```text
View
  -> ViewModel
  -> Repository
  -> DatabaseService
  -> SQLite
```

也就是说：

- `View` 只负责展示和用户操作。
- `ViewModel` 只负责页面状态和业务流程。
- `Repository` 决定数据来自网络、数据库，还是两者结合。
- `DatabaseService` 只负责本地数据库读写。

不要这样做：

```text
View 直接查数据库
ViewModel 直接写 SQL
Repository 直接 import sqflite
```

这样会让页面、状态、存储混在一起，后面测试和维护都会变麻烦。

#### Repository 如何同时使用网络和数据库

以订单模块为例，Repository 可以同时依赖 `ApiService` 和 `DatabaseService`：

```dart
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({
    required ApiService apiService,
    required DatabaseService databaseService,
  })  : _apiService = apiService,
        _databaseService = databaseService;

  final ApiService _apiService;
  final DatabaseService _databaseService;
}
```

常见策略是：

```text
先读数据库缓存
  -> 页面尽快展示旧数据

再请求网络
  -> 请求成功后写入数据库
  -> 页面展示最新数据
```

这种写法能兼顾打开速度和数据新鲜度。

#### 通用缓存表示例

项目默认创建了一张通用缓存表：

```text
app_cache
  cache_key     TEXT PRIMARY KEY
  cache_value   TEXT NOT NULL
  updated_at    INTEGER NOT NULL
```

它适合保存简单 JSON 缓存，比如：

- 首页 banner 快照
- 字典配置
- 筛选条件配置
- 一些不复杂的接口响应

如果数据结构复杂，比如订单、商品、消息列表，建议单独建表，不要全部塞进 `app_cache`。

#### 新增一张表怎么做

比如你要新增订单表 `orders`。

第一步：在 [lib/core/database/database_tables.dart](lib/core/database/database_tables.dart) 中增加表名和字段名：

```dart
static const String orders = 'orders';
static const String orderId = 'order_id';
static const String orderTitle = 'title';
static const String orderUpdatedAt = 'updated_at';
```

第二步：在 [lib/core/database/database_migrations.dart](lib/core/database/database_migrations.dart) 中把版本号加 1：

```dart
static const int currentVersion = 2;
```

第三步：给新版本增加 migration：

```dart
case 2:
  await _createVersion2(db);
  break;
```

然后写建表 SQL：

```dart
static Future<void> _createVersion2(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS ${DatabaseTables.orders} (
      ${DatabaseTables.orderId} TEXT PRIMARY KEY,
      ${DatabaseTables.orderTitle} TEXT NOT NULL,
      ${DatabaseTables.orderUpdatedAt} INTEGER NOT NULL
    )
  ''');
}
```

注意：已经上线的 App 不要随便删表重建。新增字段、新增表、创建索引都应该通过 migration 完成。

#### 新模块怎么接入数据库

比如 `order` 模块需要本地缓存。

推荐顺序：

```text
1. 在 database_tables.dart 中定义 orders 表和字段
2. 在 database_migrations.dart 中新增 migration
3. 在 OrderRepositoryImpl 中注入 DatabaseService
4. Repository 里把数据库 Map 转成 OrderModel
5. ViewModel 继续只调用 OrderRepository
6. View 继续只调用 OrderViewModel
```

注册依赖时：

```dart
locator.registerLazySingleton<OrderRepository>(
  () => OrderRepositoryImpl(
    apiService: locator(),
    databaseService: locator(),
  ),
);
```

这样写之后，`OrderViewModel` 不需要知道订单数据是从网络来的，还是从数据库来的。

#### 数据库层的使用边界

请记住这几条：

- 不要在 `View` 里查数据库。
- 不要在 `ViewModel` 里写 SQL。
- 不要让 `Repository` 直接依赖 `sqflite`。
- 表名和字段名统一放在 `DatabaseTables`。
- 数据库版本升级统一放在 `DatabaseMigrations`。
- 单元测试里用 fake `DatabaseService`，不要真的打开 SQLite。

### 3.4 core/network

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}
```

### 3. 定义 Repository 接口和实现

如果 Repository 里需要把列表缓存成 JSON 字符串，记得导入：

```dart
import 'dart:convert';
```

```dart
abstract class OrderRepository {
  Future<List<OrderModel>> fetchOrders({CancelToken? cancelToken});
}

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({
    required ApiService apiService,
    required DatabaseService databaseService,
  })  : _apiService = apiService,
        _databaseService = databaseService;

  final ApiService _apiService;
  final DatabaseService _databaseService;

  @override
  Future<List<OrderModel>> fetchOrders({CancelToken? cancelToken}) async {
    // 示例：先查询数据库缓存，让页面在弱网时也有数据可展示。
    final cachedRows = await _databaseService.query(
      DatabaseTables.appCache,
      where: '${DatabaseTables.cacheKey} = ?',
      whereArgs: ['orders'],
      limit: 1,
    );

    if (cachedRows.isNotEmpty) {
      final cacheValue = cachedRows.first[DatabaseTables.cacheValue] as String;
      final cachedJson = jsonDecode(cacheValue) as List<dynamic>;
      final cachedOrders = asList(cachedJson, OrderModel.fromJson);

      if (cachedOrders.isNotEmpty) {
        return cachedOrders;
      }
    }

    final response = await _apiService.get<List<OrderModel>>(
      '/orders',
      cancelToken: cancelToken,
      fromJson: (json) => asList(
        json,
        OrderModel.fromJson,
      ),
    );
    final orderList = response.data ?? [];

    // 示例：网络成功后，把接口结果写入数据库。
    // 这里为了演示使用通用缓存表，复杂订单数据建议单独建 orders 表。
    await _databaseService.insert(
      DatabaseTables.appCache,
      {
        DatabaseTables.cacheKey: 'orders',
        DatabaseTables.cacheValue: jsonEncode(
          orderList.map((order) => order.toJson()).toList(),
        ),
        DatabaseTables.cacheUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      replaceOnConflict: true,
    );

    return orderList;
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
  () => OrderRepositoryImpl(
    apiService: locator(),
    databaseService: locator(),
  ),
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

### 4. 按需接入本地数据库缓存

如果某个接口需要离线展示、减少重复请求、提升打开速度，可以在对应 Repository 中同时注入 `DatabaseService`。

推荐做法：

```text
Repository 先读数据库缓存
  -> 有缓存时先返回缓存
  -> 没缓存或需要刷新时请求网络
  -> 网络成功后写入数据库
```

注意：不要在 ViewModel 里直接操作数据库。ViewModel 仍然只调用 Repository。

### 5. 确认响应结构

如果后端响应不是：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

需要修改 [lib/core/network/api_response.dart](lib/core/network/api_response.dart)。

### 6. 确认成功码

默认业务成功码是 `0`。

如果后端是 HTTP 状态码模式，可以启动时传：

```bash
flutter run --dart-define=ENV_USE_HTTP_STATUS=true
```

如果后端业务成功码不是 0，可以传：

```bash
flutter run --dart-define=ENV_API_SUCCESS_CODE=200
```

## 10. 如何编写单元测试

这个项目的单元测试重点是：**测试业务逻辑，不测试真实网络，也不测试真实数据库**。

因此测试 ViewModel 时，不要真的请求 Dio，也不要直接手动 `new ViewModel(FakeRepository())`。推荐做法是：

```text
测试中注册 fake Repository
  -> 通过 get_it 注册 ViewModel
  -> 从 locator 获取 ViewModel
  -> 调用 ViewModel 方法
  -> 断言 ViewModel 暴露给 View 的字段
```

这样测试创建链路和真实页面保持一致：

```text
真实页面：
BasePage create -> locator<HomeViewModel>() -> HomeRepositoryImpl -> ApiService / DatabaseService

单元测试：
locator<HomeViewModel>() -> FakeHomeRepository
```

差别只在于测试里把真实 Repository 替换成 fake Repository。
如果要测试 Repository，则把真实 `ApiService`、真实 `DatabaseService` 替换成 fake。

### 10.1 测试目录建议

测试目录建议和 `lib/features` 对齐：

```text
test/
  features/
    login/
      login_view_model_test.dart
    home/
      home_view_model_test.dart
```

这样别人看到测试文件，就能马上知道它对应哪个业务模块。

### 10.2 ViewModel 单元测试写法

以 `LoginViewModel` 为例。

第一步：写一个 fake Repository。

```dart
class FakeLoginRepository implements LoginRepository {
  @override
  Future<LoginResponse> login(
    LoginRequest request, {
    CancelToken? cancelToken,
  }) async {
    return const LoginResponse(
      token: 'fake_token',
      user: UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
      ),
    );
  }
}
```

第二步：在 `setUp` 里注册 fake。

```dart
setUp(() async {
  await locator.reset();

  locator.registerLazySingleton<LoginRepository>(
    FakeLoginRepository.new,
  );

  locator.registerFactory<LoginViewModel>(
    () => LoginViewModel(locator<LoginRepository>()),
  );
});
```

第三步：在 `tearDown` 里清理容器。

```dart
tearDown(() async {
  await locator.reset();
});
```

第四步：从 `locator` 获取 ViewModel 并测试。

```dart
test('login view model uses fake repository registered in get_it', () async {
  final viewModel = locator<LoginViewModel>();

  final success = await viewModel.login('test@example.com', '123456');

  expect(success, isTrue);
  expect(viewModel.token, 'fake_token');
  expect(viewModel.user?.name, 'Test User');
});
```

### 10.3 列表页 ViewModel 测试写法

以 `HomeViewModel` 为例。

```dart
class FakeHomeRepository implements HomeRepository {
  @override
  Future<List<HomeBanner>> fetchBanners({
    CancelToken? cancelToken,
  }) async {
    return const [
      HomeBanner(id: '1', title: 'Fake Banner', imageUrl: ''),
    ];
  }
}
```

测试中注册：

```dart
setUp(() async {
  await locator.reset();

  locator.registerLazySingleton<HomeRepository>(
    FakeHomeRepository.new,
  );

  locator.registerFactory<HomeViewModel>(
    () => HomeViewModel(locator<HomeRepository>()),
  );
});
```

断言 ViewModel 暴露给 View 的字段：

```dart
test('home view model uses fake repository registered in get_it', () async {
  final viewModel = locator<HomeViewModel>();

  await viewModel.loadHome();

  expect(viewModel.bannerList, hasLength(1));
  expect(viewModel.bannerList.first.title, 'Fake Banner');
});
```

### 10.4 为什么测试里也要用 get_it

不要这样写：

```dart
final viewModel = LoginViewModel(FakeLoginRepository());
```

虽然它能测，但它绕过了项目真实的依赖创建方式。

推荐这样写：

```dart
locator.registerLazySingleton<LoginRepository>(
  FakeLoginRepository.new,
);

locator.registerFactory<LoginViewModel>(
  () => LoginViewModel(locator<LoginRepository>()),
);

final viewModel = locator<LoginViewModel>();
```

好处：

- 测试路径和真实页面路径一致。
- 可以验证 DI 注册方式是否合理。
- 后续 ViewModel 构造参数变化时，测试更容易暴露问题。
- Repository / ApiService 可以逐层替换 fake 实现。

### 10.5 setUp / tearDown 注意点

每个测试文件都建议写：

```dart
setUp(() async {
  await locator.reset();
  // 注册当前测试需要的 fake 和 ViewModel
});

tearDown(() async {
  await locator.reset();
});
```

原因：

- 避免不同测试之间共享同一个 Repository 或 ViewModel。
- 避免上一个测试注册的 fake 影响下一个测试。
- 保证每个测试都是独立的。

如果是 Widget 测试，并且涉及本地存储，还要 mock 存储：

```dart
SharedPreferences.setMockInitialValues({});
FlutterSecureStorage.setMockInitialValues({});
await LocalStorage.init();
await setupServiceLocator();
```

### 10.6 Repository 测试如何 fake 数据库

Repository 如果同时依赖网络和数据库，不要在单元测试里真的打开 SQLite。

推荐写一个 fake `DatabaseService`：

```dart
class FakeDatabaseService implements DatabaseService {
  final Map<String, List<Map<String, Object?>>> tables = {};

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    bool replaceOnConflict = false,
  }) async {
    final rows = tables.putIfAbsent(table, () => []);
    rows.add(values);
    return rows.length;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool distinct = false,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return tables[table] ?? [];
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return 0;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    tables.remove(table);
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, {
    List<Object?>? arguments,
  }) async {
    return [];
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(DatabaseService service) action,
  ) {
    return action(this);
  }

  @override
  Future<void> clearTable(String table) async {
    tables.remove(table);
  }
}
```

测试 Repository 时可以这样注册：

```dart
setUp(() async {
  await locator.reset();

  locator.registerLazySingleton<ApiService>(
    FakeApiService.new,
  );

  locator.registerLazySingleton<DatabaseService>(
    FakeDatabaseService.new,
  );

  locator.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      apiService: locator(),
      databaseService: locator(),
    ),
  );
});
```

这样测试的是 Repository 的数据转换和缓存逻辑，不依赖真实网络和真实 SQLite。

### 10.7 应该测什么，不应该测什么

ViewModel 单元测试应该测：

- 调用成功后，ViewModel 暴露给 View 的字段是否正确。
- 空数据时是否进入 empty 状态。
- 业务失败时是否进入 error 状态。
- 表单校验逻辑是否正确。
- 是否调用了 fake Repository 的预期方法。

ViewModel 单元测试不应该测：

- Dio 真实网络请求。
- UI 具体长什么样。
- GoRouter 是否真的跳转。
- SharedPreferences / SecureStorage 的真实读写。
- SQLite 的真实文件读写。

Repository 单元测试可以测：

- JSON 是否能正确转 Model。
- 缓存命中时是否优先返回缓存。
- fake ApiService 返回不同数据时，Repository 是否转换正确。
- fake DatabaseService 有缓存时，Repository 是否按预期读取缓存。

Widget 测试可以测：

- 未登录时是否显示登录页。
- 登录按钮点击后是否进入主页面。
- 页面上关键文案或按钮是否存在。

### 10.7 当前已有测试示例

可以参考：

- [test/features/login/login_view_model_test.dart](test/features/login/login_view_model_test.dart)
- [test/features/home/home_view_model_test.dart](test/features/home/home_view_model_test.dart)
- [test/features/login/login_page_navigation_test.dart](test/features/login/login_page_navigation_test.dart)
- [test/core/router/app_router_test.dart](test/core/router/app_router_test.dart)

## 11. 常用命令

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

## 12. 开发约定

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
- 单元测试中也通过 `get_it` 注册 fake 实现，再通过 `locator<ViewModel>()` 获取被测对象。

## 13. 一句话理解这个架构

这个项目的核心思想是：

```text
Provider 管全局状态和页面刷新，
ViewModel 管页面状态和业务流程，
Repository 管数据来源和数据转换，
ApiClient 管网络请求和异常处理，
GoRouter 管声明式路由和登录拦截。
```

只要后续开发遵守这个数据流，项目规模变大后依然能保持清晰、可测试、可维护。
