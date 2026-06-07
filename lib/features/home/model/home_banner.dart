// lib/features/home/model/home_banner.dart
//
// 作用：首页 Banner 数据模型，定义 Banner 的数据结构。
//
// 放在 features/home/model/ 的原因：
// HomeBanner 是首页模块专用的数据模型，其他模块不会用到，
// 所以放在 features/home 下而不是 shared/models。
//
// 设计要点：
// 1. 使用 json_helper 的安全类型转换（asOr），避免后端字段异常导致崩溃
// 2. 提供 copyWith 方法，方便局部更新 banner 字段
// 3. 手写 operator== 和 hashCode，不依赖外部包
// 4. 使用 const 构造函数，所有字段都是 final

import '../../../core/utils/json_helper.dart';

/// 首页 Banner 数据模型。
///
/// 当前保留 imageUrl 字段，后续接入真实图片时不需要修改页面结构，
/// 只需要在 HomeRepository 中把模拟数据替换为真实接口数据即可。
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  /// Banner 唯一标识
  final String id;

  /// Banner 标题
  final String title;

  /// Banner 图片 URL，当前为模拟数据，接入真实后端后由接口返回
  final String imageUrl;

  /// 从 JSON Map 创建 HomeBanner 实例。
  ///
  /// 后端字段缺失时使用空字符串兜底，保证 UI 渲染不会空指针。
  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: asOr(json['id'], ''),
      title: asOr(json['title'], ''),
      imageUrl: asOr(json['imageUrl'], ''),
    );
  }

  /// 创建 HomeBanner 的副本，只修改指定的字段。
  ///
  /// 使用场景：局部更新 banner 信息（如只替换标题或图片）。
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

  /// 相等性比较：所有字段相等才认为两个 HomeBanner 相等。
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeBanner &&
            other.id == id &&
            other.title == title &&
            other.imageUrl == imageUrl;
  }

  /// 基于所有字段计算哈希值。
  @override
  int get hashCode => Object.hash(id, title, imageUrl);
}