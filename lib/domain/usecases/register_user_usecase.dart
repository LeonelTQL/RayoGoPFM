import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class RegisterUserUsecase {
  final AuthRepository repository;
  const RegisterUserUsecase(this.repository);

  Future<AppUser> call({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) {
    return repository.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
  }
}
