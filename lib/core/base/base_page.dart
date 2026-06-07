// lib/core/base/base_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/state_view.dart';
import 'base_view_model.dart';

enum LoadingStyle { replace, overlay }

typedef ViewModelBuilder<VM extends BaseViewModel> = Widget Function(
  BuildContext context,
  VM viewModel,
);

// 通用页面容器：负责创建 ViewModel、监听状态，并自动切换 loading/error/empty/content。
class BasePage<VM extends BaseViewModel> extends StatefulWidget {
  const BasePage({
    super.key,
    required this.create,
    required this.builder,
    this.onModelReady,
    this.onRetry,
    this.loadingStyle = LoadingStyle.replace,
  });

  final VM Function() create;
  final ViewModelBuilder<VM> builder;
  final void Function(VM viewModel)? onModelReady;
  final void Function(VM viewModel)? onRetry;
  final LoadingStyle loadingStyle;

  @override
  State<BasePage<VM>> createState() => _BasePageState<VM>();
}

class _BasePageState<VM extends BaseViewModel> extends State<BasePage<VM>> {
  late final VM _viewModel;

  @override
  void initState() {
    super.initState();
    // ViewModel 只创建一次，避免 build 重复执行时重复请求或丢失状态。
    _viewModel = widget.create();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onModelReady?.call(_viewModel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用 create 交给 Provider 管理生命周期，页面销毁时 ViewModel 会自动 dispose。
    return ChangeNotifierProvider<VM>(
      create: (_) => _viewModel,
      child: Consumer<VM>(
        builder: (context, viewModel, _) {
          return StateView(
            state: viewModel.viewState,
            errorMessage: viewModel.errorMessage,
            onRetry: widget.onRetry == null
                ? null
                : () => widget.onRetry!.call(viewModel),
            loadingStyle: widget.loadingStyle,
            child: widget.builder(context, viewModel),
          );
        },
      ),
    );
  }
}
