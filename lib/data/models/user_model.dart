import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.avatarUrl,
    super.hasPassword = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'cliente',
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
      hasPassword: json['hasPassword'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatarUrl': avatarUrl,
        'hasPassword': hasPassword,
      };

  @override
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? hasPassword,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }
}
