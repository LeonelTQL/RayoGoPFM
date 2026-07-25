import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/local/session_local_datasource.dart';
import '../datasource/remote/api_client.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SessionLocalDatasource session;

  AuthRepositoryImpl({required this.apiClient, required this.session});

  @override
  Future<AppUser> login(String email, String password) async {
    final json = await apiClient.post('/auth/login', {'email': email, 'password': password});
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await session.saveSession(json['token'].toString(), user);
    return user;
  }

  @override
  Future<AppUser> loginWithGoogle({required String email, required String name, required String googleId, String? avatarUrl}) async {
    final json = await apiClient.post('/auth/google-login', {
      'email': email,
      'name': name,
      'googleId': googleId,
      'avatarUrl': avatarUrl,
    });
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await session.saveSession(json['token'].toString(), user);
    return user;
  }

  @override
  Future<AppUser> register({required String name, required String email, required String password, required String phone}) async {
    final json = await apiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await session.saveSession(json['token'].toString(), user);
    return user;
  }

  @override
  Future<void> changeRole(String userId, String newRole) async {
    await apiClient.post('/auth/change-role', {
      'userId': userId,
      'newRole': newRole,
    });
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    final response = await apiClient.get('/auth/users');
    final list = response as List;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AppUser?> currentUser() => session.getUser();

  @override
  Future<void> logout() => session.clear();

  @override
  Future<void> updatePhone(String phone) async {
    final json = await apiClient.put('/auth/update-phone', {'phone': phone});
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    final token = await session.getToken();
    if (token != null) {
      await session.saveSession(token, user);
    }
  }

  @override
  Future<void> deleteAccount() async {
    await apiClient.delete('/auth/delete-account');
    await session.clear();
  }

  @override
  Future<void> changePassword({String? currentPassword, required String newPassword}) async {
    final json = await apiClient.put('/auth/change-password', {
      if (currentPassword != null) 'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    final token = await session.getToken();
    if (token != null) {
      await session.saveSession(token, user);
    }
  }
}
