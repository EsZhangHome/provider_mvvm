// lib/core/base/base_view_model.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import 'view_state.dart';

class BaseViewModel extends ChangeNotifier {
  // 默认 idle，表示页面刚创建，还没有开始请求数据。
  ViewState _viewState = ViewState.idle;
  String _errorMessage = '';
  bool _disposed = false;
  bool _isRequesting = false;

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
  Future<T?> asyncRequest<T>(
    Future<T> Function() request, {
    bool Function(T data)? isEmpty,
    String? errorMessage,
    CancelToken? cancelToken,
  }) async {
    if (_isRequesting) {
      return null;
    }
    final activeCancelToken = cancelToken ?? this.cancelToken;
    if (activeCancelToken.isCancelled) {
      return null;
    }
    try {
      _isRequesting = true;
      setLoading();
      final data = await request();
      if (isEmpty != null && isEmpty(data)) {
        setEmpty();
      } else {
        setSuccess();
      }
      return data;
    } catch (error) {
      if (error is BusinessException) {
        setError(error.userMessage);
      } else {
        setError(errorMessage ?? error.toString());
      }
      return null;
    } finally {
      _isRequesting = false;
    }
  }

  void forceResetRequesting() {
    _isRequesting = false;
  }

  @override
  void dispose() {
    // 标记已销毁，后续异步回调不会再 notifyListeners。
    cancelToken.cancel('viewModel disposed');
    _disposed = true;
    super.dispose();
  }
}
