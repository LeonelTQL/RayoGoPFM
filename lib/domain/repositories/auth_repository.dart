import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> login(String email, String password);
  Future<AppUser> loginWithGoogle({required String email, required String name, required String googleId, String? avatarUrl});
  Future<AppUser> register({required String name, required String email, required String password, required String phone});
  Future<AppUser?> currentUser();
  Future<void> logout();
  Future<void> changeRole(String userId, String newRole);
  Future<List<AppUser>> getAllUsers();
  Future<void> updatePhone(String phone);
  Future<void> deleteAccount();
  Future<void> changePassword({String? currentPassword, required String newPassword});
}
