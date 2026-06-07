// lib/shared/widgets/not_found_view.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/route_paths.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    // GoRouter 匹配不到页面时展示这里。
    // 不直接返回空白页，能减少用户迷路感。
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.pageNotFound),
            const SizedBox(height: 16),
            ElevatedButton(
              // 这里的 RoutePaths.home 是 /main 的别名，回到登录后的主页面。
              onPressed: () => context.go(RoutePaths.home),
              child: const Text(AppStrings.backHome),
            ),
          ],
        ),
      ),
    );
  }
}
