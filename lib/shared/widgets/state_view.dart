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
    switch (state) {
      case ViewState.loading:
        if (loadingStyle == LoadingStyle.overlay) {
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
        return const LoadingView();
      case ViewState.error:
        return ErrorView(message: errorMessage, onRetry: onRetry);
      case ViewState.empty:
        return const EmptyView();
      case ViewState.idle:
      case ViewState.success:
        return child;
    }
  }
}
