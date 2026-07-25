import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class LoginUserUsecase {
  final AuthRepository repository;
  const LoginUserUsecase(this.repository);
  Future<AppUser> call(String email, String password) => repository.login(email, password);
}
