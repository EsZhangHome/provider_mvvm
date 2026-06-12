// lib/core/base/base_view_model.dart
//
// 作用：所有 ViewModel 的基类，提供统一的状态管理、请求防抖、生命周期保护。
//
// 架构职责：
// - 管理 ViewState（idle/loading/success/empty/error）的切换
// - 提供 asyncRequest 统一包装异步请求，减少每个 ViewModel 的重复代码
// - 提供请求防抖机制（同一时间只允许一个 asyncRequest 执行）
// - 管理 CancelToken 生命周期（页面销毁时自动取消请求）
// - 安全 notifyListeners（dispose 后不再通知 UI，避免内存泄漏）
//
// 子类使用方式：
// ```dart
// class HomeViewModel extends BaseViewModel {
//   final HomeRepository _repository;
//   List<HomeBanner> bannerList = [];
//
//   Future<void> loadHome() async {
//     final banners = await asyncRequest<List<HomeBanner>>(
//       () => _repository.fetchBanners(cancelToken: cancelToken),
//       isEmpty: (data) => data.isEmpty,
//     );
//     if (banners != null) {
//       bannerList = banners;
//       safeNotifyListeners();
//     }
//   }
// }
// ```

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import 'view_state.dart';

/// 所有 ViewModel 的基类，不包含任何业务逻辑，只提供基础设施。
///
/// 核心能力：
/// 1. 状态管理：通过 setLoading/setSuccess/setEmpty/setError/setIdle 切换页面状态
/// 2. 异步请求封装：asyncRequest 自动处理 loading/error/success/empty
/// 3. 请求防抖：_isRequesting 确保同一时间只有一个请求在执行
/// 4. 生命周期保护：dispose 后 safeNotifyListeners 不再触发 UI 刷新
/// 5. 请求取消：页面销毁时自动 cancel 所有使用 cancelToken 的 Dio 请求
class BaseViewModel extends ChangeNotifier {
  // ==================== 私有状态字段 ====================

  /// 当前页面状态，默认 idle。
  /// 页面创建时还没有开始请求，所以是 idle 状态。
  ViewState _viewState = ViewState.idle;

  /// 错误提示文案，只有当 _viewState 为 error 时页面才会读取它。
  /// 每次切换到非 error 状态时都会被清空。
  String _errorMessage = '';

  /// 是否已执行 dispose。
  /// ChangeNotifier 在 dispose 后调用 notifyListeners 会抛出异常，
  /// 这个标记用于在异步回调中安全地跳过 UI 刷新。
  bool _disposed = false;

  /// 请求防抖标记：true 表示当前有一个 asyncRequest 正在执行中。
  ///
  /// 典型触发场景：
  /// - 用户连续下拉刷新
  /// - 按钮连续快速点击
  /// - 页面重复触发 onModelReady
  ///
  /// 当 _isRequesting 为 true 时，新的 asyncRequest 调用会直接返回 null，
  /// 不会创建重复请求。
  bool _isRequesting = false;

  // ==================== 公开属性 ====================

  /// 每个 ViewModel 自带一个 CancelToken，与页面生命周期绑定。
  ///
  /// 使用方式：
  /// - Repository 调用 Dio 时透传这个 cancelToken
  /// - ViewModel dispose 时会自动 cancel 这个 token
  /// - 所有使用此 token 的 Dio 请求都会被取消，释放网络资源
  ///
  /// 特殊场景：如果某个请求需要独立取消（不随页面销毁取消），
  /// 可以在 asyncRequest 中传入自定义 cancelToken。
  final CancelToken cancelToken = CancelToken();

  // ==================== 公开 getter ====================

  /// 当前页面状态，StateView 根据此值决定展示 loading/error/empty 或正常内容。
  ViewState get viewState => _viewState;

  /// 错误提示文案，仅在 error 状态下有意义。
  String get errorMessage => _errorMessage;

  /// 是否正在加载中，页面可以用这个 getter 禁用按钮等操作。
  bool get isLoading => _viewState == ViewState.loading;

  // ==================== 状态切换方法 ====================

  /// 切换到 loading 状态。
  ///
  /// 调用时机：开始执行异步请求时。
  /// 效果：StateView 会展示 LoadingView 或叠加 loading 遮罩。
  void setLoading() {
    _viewState = ViewState.loading;
    _errorMessage = ''; // 切换状态时清空上一次的错误信息
    safeNotifyListeners();
  }

  /// 切换到 success 状态。
  ///
  /// 调用时机：异步请求成功且返回了有效数据。
  /// 效果：StateView 会展示 child（业务页面编写的正常内容）。
  void setSuccess() {
    _viewState = ViewState.success;
    _errorMessage = '';
    safeNotifyListeners();
  }

  /// 切换到 empty 状态。
  ///
  /// 调用时机：异步请求成功但返回的数据为空（如列表长度为 0）。
  /// 效果：StateView 会展示 EmptyView，提示用户"暂无数据"。
  void setEmpty() {
    _viewState = ViewState.empty;
    _errorMessage = '';
    safeNotifyListeners();
  }

  /// 切换到 error 状态。
  ///
  /// 调用时机：异步请求失败（网络异常、超时、业务错误等）。
  /// [message] 会被展示到 ErrorView 中，建议使用对用户友好的文案。
  /// 效果：StateView 会展示 ErrorView，包含错误信息和可选的重试按钮。
  void setError(String message) {
    _viewState = ViewState.error;
    _errorMessage = message;
    safeNotifyListeners();
  }

  /// 切换到 idle 状态（回到初始状态）。
  ///
  /// 调用时机：
  /// - 表单页需要重置状态
  /// - 想要清空当前页面所有状态
  ///
  /// 效果：StateView 会直接展示 child 内容。
  void setIdle() {
    _viewState = ViewState.idle;
    _errorMessage = '';
    safeNotifyListeners();
  }

  // ==================== 安全通知方法 ====================

  /// 安全的 notifyListeners，dispose 后不会触发 UI 刷新。
  ///
  /// 为什么需要这个方法：
  /// - 异步请求可能在页面销毁后才完成
  /// - 此时如果直接调用 notifyListeners()，ChangeNotifier 会抛出异常
  /// - 通过 _disposed 标记，可以在 dispose 后安全地跳过所有 UI 刷新
  ///
  /// 使用建议：ViewModel 内部所有 notifyListeners 都应该通过这个方法调用，
  /// 而不是直接调用 notifyListeners()。
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ==================== 异步请求封装 ====================

  /// 统一包装异步请求，自动处理 loading → success/empty/error 的状态流转。
  ///
  /// 这是 ViewModel 最核心的方法，封装了以下逻辑：
  /// 1. 请求防抖：同一时间只允许一个请求（通过 _isRequesting 控制）
  /// 2. CancelToken 检查：如果 token 已取消，不再执行请求
  /// 3. 自动 loading：请求开始时自动切换到 loading 状态
  /// 4. 自动 success/empty：请求成功后根据 isEmpty 判断是 success 还是 empty
  /// 5. 自动 error 处理：捕获 BusinessException 展示业务错误，其他异常展示通用错误
  /// 6. 请求结束清理：无论成功或失败，finally 中都重置 _isRequesting
  ///
  /// 参数说明：
  /// [request]：真正的异步请求闭包，一般是调用 Repository 的方法。
  ///            使用闭包而不是直接传 Future 是为了延迟执行，保证状态切换在请求之前。
  ///
  /// [isEmpty]：判断请求结果是否为空的回调。
  ///            例如：列表接口传 (data) => data.isEmpty；
  ///            详情接口通常不需要传，因为详情不太可能为空。
  ///
  /// [errorMessage]：当发生非业务异常时，覆盖默认错误文案。
  ///                  不传时使用异常的 toString()。
  ///
  /// [cancelToken]：自定义 CancelToken。不传时使用 ViewModel 自己的 cancelToken。
  ///                 特殊场景：比如某个请求需要独立于页面生命周期管理时使用。
  ///
  /// 返回值：
  /// - 成功时返回请求结果
  /// - 失败、被防抖拦截、被取消时返回 null
  /// - 调用方需要通过判断 null 来决定是否继续后续操作
  Future<T?> asyncRequest<T>(
    Future<T> Function() request, {
    bool Function(T data)? isEmpty,
    String? errorMessage,
    CancelToken? cancelToken,
  }) async {
    // ---- 步骤 1：请求防抖检查 ----
    // 如果当前已有请求在执行，直接忽略本次调用
    // 返回 null 表示"本次没有产生新数据"
    if (_isRequesting) {
      return null;
    }

    // ---- 步骤 2：CancelToken 检查 ----
    // 使用外部传入的 cancelToken 或 ViewModel 自己的 cancelToken
    final activeCancelToken = cancelToken ?? this.cancelToken;
    // 如果 token 已经被取消（如页面已销毁），不再执行请求
    if (activeCancelToken.isCancelled) {
      return null;
    }

    try {
      // ---- 步骤 3：标记请求进行中 + 切换到 loading 状态 ----
      _isRequesting = true;
      setLoading();

      // ---- 步骤 4：执行真正的异步请求 ----
      // 这里不关心 request 内部是网络请求、缓存读取还是数据库查询
      // ViewModel 只需要拿到结果，并根据结果切换页面状态
      final data = await request();

      // ---- 步骤 5：根据结果判断 success 还是 empty ----
      if (isEmpty != null && isEmpty(data)) {
        // 请求成功但数据为空 → empty 状态
        setEmpty();
      } else {
        // 请求成功且有数据 → success 状态
        setSuccess();
      }
      return data;
    } catch (error) {
      // ---- 步骤 6：错误处理 ----
      // 区分业务异常和系统异常，给出不同的错误提示
      if (error is BusinessException) {
        // 业务异常：后端返回的业务错误（如账号冻结、余额不足、权限不够）
        // 这类错误应该直接展示后端返回的 userMessage 给用户
        setError(error.userMessage);
      } else {
        // 非业务异常：网络错误、解析错误、超时、未知错误等
        // 使用传入的 errorMessage 或异常的 toString() 作为提示
        setError(errorMessage ?? error.toString());
      }
      return null;
    } finally {
      // ---- 步骤 7：请求结束，重置防抖标记 ----
      // 无论成功还是失败，都要释放 _isRequesting
      // 这样下一次请求才能正常执行
      _isRequesting = false;
    }
  }

  /// 强制重置请求防抖标记。
  ///
  /// 使用场景：
  /// - 某些特殊业务场景需要取消当前请求并立即发起新请求
  /// - 例如：用户快速切换筛选条件，需要丢弃上一个请求的结果
  ///
  /// 注意：这个方法不会取消正在进行的网络请求，只是允许新的 asyncRequest 执行。
  /// 如果需要取消网络请求，请使用 cancelToken.cancel()。
  void forceResetRequesting() {
    _isRequesting = false;
  }

  // ==================== 生命周期 ====================

  @override
  void dispose() {
    // ---- 步骤 1：取消所有使用此 token 的 Dio 请求 ----
    // cancel 后 Dio 会抛出 CancelException，避免浪费网络资源
    cancelToken.cancel('viewModel disposed');

    // ---- 步骤 2：标记已销毁 ----
    // 后续所有异步回调在调用 safeNotifyListeners 时会被拦截
    _disposed = true;

    // ---- 步骤 3：调用父类 dispose ----
    // ChangeNotifier.dispose 会释放所有监听器
    super.dispose();
  }
}
