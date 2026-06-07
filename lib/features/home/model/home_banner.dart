// lib/features/home/model/home_banner.dart
import '../../../core/utils/json_helper.dart';

// 首页 Banner 模型。这里先保留 imageUrl，后续接真实图片时不用改页面结构。
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String imageUrl;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: asOr(json['id'], ''),
      title: asOr(json['title'], ''),
      imageUrl: asOr(json['imageUrl'], ''),
    );
  }

  HomeBanner copyWith({
    String? id,
    String? title,
    String? imageUrl,
  }) {
    return HomeBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeBanner &&
            other.id == id &&
            other.title == title &&
            other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => Object.hash(id, title, imageUrl);
}
