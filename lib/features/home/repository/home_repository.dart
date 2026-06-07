// lib/features/home/repository/home_repository.dart
import 'package:dio/dio.dart';

import '../../../core/base/cache_policy.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../model/home_banner.dart';

// 首页仓库接口。ViewModel 依赖接口，方便用假数据做单元测试。
abstract class HomeRepository {
  Future<List<HomeBanner>> fetchBanners({CancelToken? cancelToken});
}

// 首页数据仓库实现。以后首页接口变复杂，也只在这里处理数据来源。
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    ApiService? apiService,
    CachePolicy<List<HomeBanner>>? cachePolicy,
  })  : _apiService = apiService ?? ApiClient.instance,
        _cachePolicy = cachePolicy ??
            MemoryCachePolicy<List<HomeBanner>>(
              duration: const Duration(minutes: 5),
            );

  // 保留 ApiClient 依赖，真实后端接入时直接替换当前模拟数据分支。
  // ignore: unused_field
  final ApiService _apiService;
  final CachePolicy<List<HomeBanner>> _cachePolicy;

  @override
  Future<List<HomeBanner>> fetchBanners({CancelToken? cancelToken}) async {
    // 首页是典型的“缓存优先”场景：有旧数据时先展示，减少白屏时间。
    final cachedData = await _cachePolicy.readCache();
    if (cachedData != null) {
      // 返回缓存的同时，后台悄悄拉取新数据并写入缓存。
      // 后台刷新失败不影响本次页面展示，所以 catch 后吞掉。
      Future<void>(() async {
        try {
          await _fetchRemoteBanners(cancelToken: cancelToken);
        } catch (_) {}
      });
      return cachedData;
    }

    // 没有缓存时，只能等待远端数据。BaseViewModel 会显示 loading。
    final remoteData = await _fetchRemoteBanners(cancelToken: cancelToken);
    return remoteData;
  }

  Future<List<HomeBanner>> _fetchRemoteBanners(
      {CancelToken? cancelToken}) async {
    // 当前没有真实后端，先模拟接口；接入真实后端时改为下面注释里的 _apiClient.get。
    await Future<void>.delayed(const Duration(milliseconds: 600));
    const banners = [
      HomeBanner(id: '1', title: 'Provider 负责状态管理和依赖注入', imageUrl: ''),
      HomeBanner(id: '2', title: 'MVVM 让页面和业务状态分离', imageUrl: ''),
      HomeBanner(id: '3', title: 'Repository 统一数据获取和转换', imageUrl: ''),
    ];

    // 不管是真实接口还是模拟数据，拿到新数据后都写入缓存。
    await _cachePolicy.writeCache(banners);
    return banners;

    // final response = await _apiService.get<List<HomeBanner>>(
    //   Endpoints.homeBanners,
    //   cancelToken: cancelToken,
    //   fromJson: (json) => (json as List<dynamic>)
    //       .map((item) => HomeBanner.fromJson(item as Map<String, dynamic>))
    //       .toList(),
    // );
    // final data = response.data ?? [];
    // await _cachePolicy.writeCache(data);
    // return data;
  }
}
