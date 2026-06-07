// lib/shared/models/user_model.dart
//
// 作用：用户数据模型，定义用户的基本信息字段。
//
// 放在 shared/models 而不是 features/login/model 的原因：
// 用户信息在多个模块中都会用到（登录、首页、个人中心、我的页等），
// 放在 shared 中可以避免模块间的循环依赖。
//
// 设计要点：
// 1. 使用 json_helper 的安全类型转换（asOr/asOrNull），避免后端字段类型异常导致崩溃
// 2. 提供 copyWith 方法，方便局部更新用户信息（如只改昵称或头像）
// 3. 提供 toJson 方法，用于 AuthProvider 把用户信息序列化到本地存储
// 4. 手写 operator== 和 hashCode，不依赖 equatable/freezed 等外部包
// 5. 使用 const 构造函数，所有字段都是 final，确保不可变性

import '../../core/utils/json_helper.dart';

/// 用户数据模型。
///
/// 代表一个登录用户的基本信息，所有需要展示用户信息的模块都可以使用。
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  /// 用户唯一标识
  final String id;

  /// 用户昵称/姓名
  final String name;

  /// 用户邮箱
  final String email;

  /// 用户头像 URL，可能为空
  final String? avatarUrl;

  /// 从 JSON Map 创建 UserModel 实例。
  ///
  /// 使用 json_helper 做安全类型转换，避免后端字段类型异常导致崩溃。
  ///
  /// 示例：
  /// ```dart
  /// final user = UserModel.fromJson({
  ///   'id': '1',
  ///   'name': 'Tom',
  ///   'email': 'tom@example.com',
  ///   'avatarUrl': 'https://example.com/avatar.jpg',
  /// });
  /// ```
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // 必填字段使用 asOr，提供默认值防止异常
      id: asOr(json['id'], ''),
      name: asOr(json['name'], ''),
      email: asOr(json['email'], ''),
      // 可选字段使用 asOrNull，允许 null
      avatarUrl: asOrNull<String>(json['avatarUrl']),
    );
  }

  /// 创建 UserModel 的副本，只修改指定的字段。
  ///
  /// 使用场景：
  /// - 用户修改昵称后，更新内存中的用户信息
  /// - 用户上传新头像后，更新 avatarUrl
  ///
  /// 示例：
  /// ```dart
  /// final updatedUser = user.copyWith(name: 'New Name');
  /// ```
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// 序列化为 JSON Map。
  ///
  /// 当前用于 AuthProvider 把用户信息保存到 SharedPreferences。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  /// 相等性比较：所有字段相等才认为两个 UserModel 相等。
  ///
  /// 不依赖 equatable 或 freezed，手写实现减少外部依赖。
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserModel &&
            other.id == id &&
            other.name == name &&
            other.email == email &&
            other.avatarUrl == avatarUrl;
  }

  /// 基于所有字段计算哈希值。
  @override
  int get hashCode => Object.hash(id, name, email, avatarUrl);
}