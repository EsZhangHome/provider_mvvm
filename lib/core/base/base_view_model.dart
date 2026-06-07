// lib/core/base/base_view_model.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import 'view_state.dart';

class BaseViewModel extends ChangeNotifier {
  // 默认 idle，表示页面刚创建，还没有开始请求数据。
  ViewState _viewState = ViewState.idle;

  // 页面错误提示文案。只有 error 状态时页面才会读取它。
  String _errorMessage = '';

  // ChangeNotifier dispose 后不能再 notifyListeners，否则会抛异常。
  // 这个标记用于保护异步请求结束后的 UI 刷新。
  bool _disposed = false;

  // 请求防抖标记：同一个 ViewModel 同一时间只允许一个 asyncRequest 执行。
  // 典型场景：用户连续下拉刷新、按钮连续点击、页面重复触发 onModelReady。
  bool _isRequesting = false;

  // 每个 ViewModel 自带一个 CancelToken。
  // 页面销毁时会自动 cancel，Repository 透传给 Dio 后，请求就不会继续浪费资源。
  final CancelToken cancelToken = CancelToken();

  ViewState get viewState => _viewState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _viewState == ViewState.loading;

  // 开始请求数据时调用，页面通常会显示 LoadingView。
  void setLoading() {
    _viewState = ViewState.loading;
    _errorMessage = '';
    safeNotifyListeners();
  }

  // 请求成功且有数据时调用。
  void setSuccess() {
    _viewState = ViewState.success;
    _errorMessage = '';
    safeNotifyListeners();
  }

  // 请求成功但没有数据时调用，比如列表为空。
  void setEmpty() {
    _viewState = ViewState.empty;
    _errorMessage = '';
    safeNotifyListeners();
  }

  // 请求失败时调用，message 会展示到 ErrorView。
  void setError(String message) {
    _viewState = ViewState.error;
    _errorMessage = message;
    safeNotifyListeners();
  }

  // 回到初始状态，适合表单页或需要清空状态的场景。
  void setIdle() {
    _viewState = ViewState.idle;
    _errorMessage = '';
    safeNotifyListeners();
  }

  // 异步请求结束时页面可能已经销毁，这里可以避免 dispose 后继续刷新 UI。
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // 统一包装异步请求：自动 loading、success、empty、error，减少每个 ViewModel 的重复代码。
  //
  // request:
  //   真正的异步请求，一般是调用 Repository。
  //
  // isEmpty:
  //   用来判断请求成功但数据为空的场景，比如列表长度为 0。
  //
  // errorMessage:
  //   某些场景想覆盖默认错误文案时使用。
  //
  // cancelToken:
  //   默认使用 ViewModel 自己的 cancelToken；特殊场景可以从外部传入。
  Future<T?> asyncRequest<T>(
    Future<T> Function() request, {
    bool Function(T data)? isEmpty,
    String? errorMessage,
    CancelToken? cancelToken,
  }) async {
    if (_isRequesting) {
      // 已经有请求在跑，直接忽略这次触发。
      // 返回 null 代表本次没有产生新数据。
      return null;
    }
    final activeCancelToken = cancelToken ?? this.cancelToken;
    if (activeCancelToken.isCancelled) {
      // 页面已经销毁或请求已取消，不再继续执行。
      return null;
    }
    try {
      _isRequesting = true;
      setLoading();

      // 这里不关心 request 内部是网络、缓存还是数据库。
      // ViewModel 只需要拿结果并根据结果切换页面状态。
      final data = await request();
      if (isEmpty != null && isEmpty(data)) {
        setEmpty();
      } else {
        setSuccess();
      }
      return data;
    } catch (error) {
      if (error is BusinessException) {
        // 业务异常通常来自后端，例如账号冻结、余额不足。
        // 这类错误应该直接展示给用户，所以使用 userMessage。
        setError(error.userMessage);
      } else {
        // 非业务异常一般是网络错误、解析错误或未知错误。
        setError(errorMessage ?? error.toString());
      }
      return null;
    } finally {
      _isRequesting = false;
    }
  }

  void forceResetRequesting() {
    // 给特殊业务场景一个手动重置入口。
    // 例如某些页面确实需要取消上一轮请求后立刻重新发起下一轮请求。
    _isRequesting = false;
  }

  @override
  void dispose() {
    // 标记已销毁，后续异步回调不会再 notifyListeners。
    // 先取消请求，再标记 disposed；这样正在进行中的 Dio 请求会尽快结束。
    cancelToken.cancel('viewModel disposed');
    _disposed = true;
    super.dispose();
  }
}
