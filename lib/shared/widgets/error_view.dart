// lib/shared/widgets/error_view.dart
import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_spacing.dart';

// 通用错误视图，支持传入重试回调。
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 简单错误图标，让用户能快速识别当前是失败状态。
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? AppStrings.requestFailed : message,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              // 只有页面传入 onRetry 时才显示按钮。
              // 这样某些不可重试错误可以只展示文案。
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
