// test/features/home/home_view_model_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_mvvm/core/di/service_locator.dart';
import 'package:provider_mvvm/features/home/model/home_banner.dart';
import 'package:provider_mvvm/features/home/repository/home_repository.dart';
import 'package:provider_mvvm/features/home/view_model/home_view_model.dart';

class FakeHomeRepository implements HomeRepository {
  @override
  Future<List<HomeBanner>> fetchBanners({CancelToken? cancelToken}) async {
    return const [
      HomeBanner(id: '1', title: 'Fake Banner', imageUrl: ''),
    ];
  }
}

void main() {
  setUp(() async {
    await locator.reset();

    // 和真实 App 一样先注册 Repository，再注册依赖它的 ViewModel。
    // 区别是这里注册的是 FakeHomeRepository，避免单元测试真的请求网络。
    locator.registerLazySingleton<HomeRepository>(
      FakeHomeRepository.new,
    );
    locator.registerFactory<HomeViewModel>(
      () => HomeViewModel(locator<HomeRepository>()),
    );
  });

  tearDown(() async {
    await locator.reset();
  });

  test('home view model uses fake repository registered in get_it', () async {
    final viewModel = locator<HomeViewModel>();

    await viewModel.loadHome();

    expect(viewModel.bannerList, hasLength(1));
    expect(viewModel.bannerList.first.title, 'Fake Banner');
  });
}
