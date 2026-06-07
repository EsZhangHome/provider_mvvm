// lib/shared/widgets/empty_view.dart
import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';

// 通用空数据视图，比如列表接口成功但没有任何数据。
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message = AppStrings.noData});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}
