abstract class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;
  final bool hasPassword;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.hasPassword = true,
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? hasPassword,
  });

  Map<String, dynamic> toJson();

  bool get isAdmin => role == 'admin';
  bool get isClient => role == 'cliente';
  bool get isDelivery => role == 'repartidor';
}
