// lib/shared/widgets/state_view.dart
import 'package:flutter/material.dart';

import '../../core/base/base_page.dart';
import '../../core/base/view_state.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

// 根据 ViewState 自动选择展示 loading、error、empty 或真实内容。
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.state,
    required this.child,
    this.errorMessage = '',
    this.onRetry,
    this.loadingStyle = LoadingStyle.replace,
  });

  final ViewState state;
  final Widget child;
  final String errorMessage;
  final VoidCallback? onRetry;
  final LoadingStyle loadingStyle;

  @override
  Widget build(BuildContext context) {
    // StateView 是页面状态展示的唯一入口。
    // 业务页面只需要提供 child，loading/error/empty 都在这里统一处理。
    switch (state) {
      case ViewState.loading:
        if (loadingStyle == LoadingStyle.overlay) {
          // overlay 模式：保留原页面内容，同时盖一层半透明 loading。
          // 适合登录、提交表单等不希望页面内容消失的场景。
          return Stack(
            children: [
              child,
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        // replace 模式：用 LoadingView 替换整个内容区。
        // 适合列表页首次加载。
        return const LoadingView();
      case ViewState.error:
        // error 状态显示错误页，onRetry 不为空时展示重试按钮。
        return ErrorView(message: errorMessage, onRetry: onRetry);
      case ViewState.empty:
        // empty 状态表示请求成功但没有数据。
        return const EmptyView();
      case ViewState.idle:
      case ViewState.success:
        // idle 和 success 都展示真实内容。
        // idle 常用于页面刚创建但还没开始请求的瞬间。
        return child;
    }
  }
}
