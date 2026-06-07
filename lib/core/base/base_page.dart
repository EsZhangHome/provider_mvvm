// lib/core/base/base_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/state_view.dart';
import 'base_view_model.dart';

enum LoadingStyle { replace, overlay }

// 页面内容构建函数。
// BasePage 已经帮我们拿到了 ViewModel，所以业务页面只需要关心 UI 怎么画。
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

  // 真正的页面内容构建器。
  // 注意：这里不应该再自己写 loading/error/empty 判断，交给 StateView 即可。
  final ViewModelBuilder<VM> builder;

  // ViewModel 创建完成后，在首帧结束时回调。
  // 适合放页面初始化请求，避免在 build 阶段直接触发 notifyListeners。
  final void Function(VM viewModel)? onModelReady;

  // 错误页点击“重试”时触发，一般再次调用 loadXxx。
  final void Function(VM viewModel)? onRetry;

  // loading 展示方式：
  // replace：用 LoadingView 替换内容，适合列表页首次加载。
  // overlay：在原内容上盖一层 loading，适合表单提交。
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
    // 这里的 _viewModel 是 initState 中创建的同一个对象，不会因为 build 重复执行而重新创建。
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
