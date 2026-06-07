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
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  @override
  bool operator ==(Object other) {
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
