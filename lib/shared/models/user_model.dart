// lib/shared/models/user_model.dart
import '../../core/utils/json_helper.dart';

// 用户模型放 shared，是因为登录、首页、个人中心等模块都可能会用到。
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 使用 json_helper 做安全类型转换，避免后端字段类型异常导致崩溃。
    return UserModel(
      id: asOr(json['id'], ''),
      name: asOr(json['name'], ''),
      email: asOr(json['email'], ''),
      avatarUrl: asOrNull<String>(json['avatarUrl']),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    // copyWith 用于局部更新用户信息，例如只改昵称或头像。
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    // 当前用于 AuthProvider 把用户信息保存到 LocalStorage。
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    // 手写相等比较，方便测试和状态比较，不额外引入 equatable/freezed。
    return identical(this, other) ||
        other is UserModel &&
            other.id == id &&
            other.name == name &&
            other.email == email &&
            other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode => Object.hash(id, name, email, avatarUrl);
}
