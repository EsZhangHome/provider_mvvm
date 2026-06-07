// lib/core/base/base_page.dart
//
// 作用：通用页面容器，负责创建 ViewModel、监听状态变化，并自动切换 loading/error/empty/content。
//
// 架构职责：
// - 创建 ViewModel 实例（通过 create 回调，由 get_it 提供）
// - 在首帧渲染完成后触发 onModelReady（避免在 build 阶段发起请求）
// - 通过 StateView 自动根据 ViewState 切换 UI
// - 提供 onRetry 回调，让错误页的重试按钮可以重新请求数据
//
// 使用方式：
// ```dart
// BasePage<HomeViewModel>(
//   create: () => locator<HomeViewModel>(),
//   onModelReady: (vm) => vm.loadHome(),
//   onRetry: (vm) => vm.loadHome(),
//   builder: (context, vm) {
//     // 这里只写正常内容的 UI，loading/error/empty 由 BasePage 处理
//     return ListView(...);
//   },
// )
// ```
//
// 数据流：
// 1. BasePage 创建 ViewModel
// 2. onModelReady 触发 ViewModel.loadXxx()
// 3. ViewModel.asyncRequest 内部调用 setLoading/setSuccess/setEmpty/setError
// 4. ChangeNotifierProvider + Consumer 监听 ViewModel 变化
// 5. StateView 根据 viewState 切换 UI
// 6. 用户看到 loading → 内容 / 错误 / 空状态

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/state_view.dart';
import 'base_view_model.dart';

/// loading 展示方式枚举。
///
/// 两种模式的选择建议：
/// - replace：适合列表页首次加载，整个页面替换为加载动画
/// - overlay：适合表单提交，保留原页面内容，在上面叠加半透明遮罩
enum LoadingStyle {
  /// 替换模式：用 LoadingView 替换整个内容区域。
  /// 适用场景：列表页首次加载、详情页加载。
  replace,

  /// 叠加模式：在原内容上方叠加一层半透明 loading 遮罩。
  /// 适用场景：登录提交、表单提交、不希望页面内容消失的操作。
  overlay,
}

/// 页面内容构建函数类型。
///
/// [context]：当前 BuildContext，可用于获取主题、Navigator 等
/// [viewModel]：对应页面的 ViewModel 实例，已经由 BasePage 创建好
///
/// 注意：builder 中不需要自己判断 loading/error/empty 状态，
/// 这些都由 BasePage + StateView 自动处理。
typedef ViewModelBuilder<VM extends BaseViewModel> = Widget Function(
  BuildContext context,
  VM viewModel,
);

/// 通用页面容器：负责创建 ViewModel、监听状态，并自动切换 loading/error/empty/content。
///
/// 这是整个 MVVM 架构中 View 层的核心组件。
/// 每个业务页面只需要继承或组合 BasePage，就不需要重复编写：
/// - ViewModel 创建和生命周期管理
/// - loading/error/empty 状态判断和 UI 切换
/// - 请求防抖和页面销毁时的请求取消
///
/// 泛型参数：
/// [VM]：对应的 ViewModel 类型，必须继承自 BaseViewModel。
class BasePage<VM extends BaseViewModel> extends StatefulWidget {
  const BasePage({
    super.key,
    required this.create,
    required this.builder,
    this.onModelReady,
    this.onRetry,
    this.loadingStyle = LoadingStyle.replace,
  });

  /// 创建 ViewModel 的工厂函数。
  ///
  /// 通常通过 get_it 获取：
  /// ```dart
  /// create: () => locator<HomeViewModel>()
  /// ```
  ///
  /// 注意：这个函数只在 initState 中调用一次，所以 ViewModel 实例在整个页面生命周期内保持不变。
  final VM Function() create;

  /// 真正的页面内容构建器。
  ///
  /// 当 StateView 判断当前状态为 idle 或 success 时，会调用这个 builder 渲染业务内容。
  ///
  /// 重要：这个 builder 不应该再自己写 loading/error/empty 的判断逻辑，
  /// 那些都交给 StateView 统一处理。这里只需要关心"正常数据长什么样"。
  final ViewModelBuilder<VM> builder;

  /// ViewModel 创建完成后，在首帧渲染结束时回调。
  ///
  /// 为什么放在首帧结束后而不是 initState 中：
  /// - initState 在 build 之前执行，此时调用 setState/notifyListeners 会导致问题
  /// - addPostFrameCallback 确保首帧已经渲染完成，此时修改状态会触发正常的 rebuild
  ///
  /// 典型用法：
  /// ```dart
  /// onModelReady: (viewModel) => viewModel.loadHome()
  /// ```
  final void Function(VM viewModel)? onModelReady;

  /// 错误页点击"重试"按钮时回调。
  ///
  /// 典型用法：
  /// ```dart
  /// onRetry: (viewModel) => viewModel.loadHome()
  /// ```
  ///
  /// 如果为 null，ErrorView 不会显示重试按钮。
  final void Function(VM viewModel)? onRetry;

  /// loading 展示方式，默认为 replace。
  ///
  /// - replace：用 LoadingView 替换内容，适合列表页首次加载
  /// - overlay：在原内容上盖一层 loading，适合表单提交
  final LoadingStyle loadingStyle;

  @override
  State<BasePage<VM>> createState() => _BasePageState<VM>();
}

class _BasePageState<VM extends BaseViewModel> extends State<BasePage<VM>> {
  /// ViewModel 实例，在 initState 中创建，整个生命周期不变。
  late final VM _viewModel;

  @override
  void initState() {
    super.initState();

    // ---- 步骤 1：创建 ViewModel ----
    // ViewModel 只创建一次，避免 build 重复执行时重复请求或丢失状态
    _viewModel = widget.create();

    // ---- 步骤 2：在首帧渲染完成后触发 onModelReady ----
    // 使用 addPostFrameCallback 确保不在 build 阶段修改状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 回调前检查 mounted，防止页面在首帧渲染前就被销毁
      if (mounted) {
        widget.onModelReady?.call(_viewModel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ---- 步骤 3：用 ChangeNotifierProvider 包装 ViewModel ----
    // Provider 负责管理 ViewModel 的生命周期，页面销毁时自动 dispose
    // 这里的 _viewModel 是 initState 中创建的同一个对象，
    // 不会因为 build 重复执行而重新创建
    return ChangeNotifierProvider<VM>(
      create: (_) => _viewModel,
      child: Consumer<VM>(
        builder: (context, viewModel, _) {
          // ---- 步骤 4：通过 StateView 自动切换 UI ----
          // StateView 根据 viewModel.viewState 决定展示：
          // - loading → LoadingView 或 overlay 遮罩
          // - error → ErrorView（含重试按钮）
          // - empty → EmptyView
          // - idle/success → child（即业务页面内容）
          return StateView(
            state: viewModel.viewState,
            errorMessage: viewModel.errorMessage,
            // 只有当页面传入了 onRetry 时，ErrorView 才显示重试按钮
            onRetry: widget.onRetry == null
                ? null
                : () => widget.onRetry!.call(viewModel),
            loadingStyle: widget.loadingStyle,
            // child 是业务页面编写的正常内容
            child: widget.builder(context, viewModel),
          );
        },
      ),
    );
  }
}