// lib/features/home/view_model/home_view_model.dart
import '../../../core/base/base_view_model.dart';
import '../model/home_banner.dart';
import '../repository/home_repository.dart';

// 首页 ViewModel：负责请求首页数据，并把 bannerList 暴露给页面。
class HomeViewModel extends BaseViewModel {
  HomeViewModel(this._repository);

  final HomeRepository _repository;

  List<HomeBanner> bannerList = [];

  // 页面进来时调用。列表为空时会进入 empty 状态。
  Future<void> loadHome() async {
    // ViewModel 不知道数据来自缓存还是网络，这些细节都封装在 Repository。
    final banners = await asyncRequest<List<HomeBanner>>(
      () => _repository.fetchBanners(cancelToken: cancelToken),
      isEmpty: (data) => data.isEmpty,
      cancelToken: cancelToken,
    );
    if (banners != null) {
      // 更新页面可见字段，然后通知 UI 刷新。
      bannerList = banners;
      safeNotifyListeners();
    }
  }
}
