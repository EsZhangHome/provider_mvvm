// test/features/main/main_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/features/main/view_model/main_view_model.dart';

void main() {
  test('main view model only manages selected tab index', () {
    final viewModel = MainViewModel();

    expect(viewModel.tabIndex, 0);

    viewModel.setTabIndex(2);

    expect(viewModel.tabIndex, 2);
  });
}
