// lib/shared/widgets/loading_view.dart
import 'package:flutter/material.dart';

// 通用加载视图，所有页面 loading 状态都可以复用。
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
