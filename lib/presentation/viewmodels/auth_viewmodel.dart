import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../data/datasource/remote/api_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;
  AuthViewModel(this.repository);

  AppUser? user;
  List<AppUser> users = [];
  bool loading = false;
  String? error;
  Map<String, String> fieldErrors = {};

  Future<void> getUsers() async {
    await _run(() async {
      users = await repository.getAllUsers();
    });
  }

  Future<void> loadSession() async {
    user = await repository.currentUser();
    notifyListeners();
  }

  String _hashPassword(String password) {
    if (password.isEmpty) return password;
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      user = await repository.login(email.trim(), _hashPassword(password));
    });
  }

  Future<bool> loginWithGoogle({required String email, required String name, required String googleId, String? avatarUrl}) async {
    return _run(() async {
      user = await repository.loginWithGoogle(email: email, name: name, googleId: googleId, avatarUrl: avatarUrl);
    });
  }

  Future<bool> register({required String name, required String email, required String password, required String phone}) async {
    return _run(() async {
      user = await repository.register(
        name: name.trim(),
        email: email.trim(),
        password: _hashPassword(password),
        phone: phone.trim(),
      );
    });
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    loading = true;
    error = null;
    notifyListeners();
    
    try {
      await repository.changeRole(userId.toString(), newRole);
      
      // Recarga completa forzada para eliminar cualquier inconsistencia de tipos
      // y notificar a todos los escuchas con los datos frescos del servidor
      final freshUsers = await repository.getAllUsers();
      users = List.from(freshUsers);
      
      if (user?.id == userId) {
        user = await repository.currentUser();
      }
      
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    user = null;
    notifyListeners();
  }

  Future<bool> updatePhone(String phone) async {
    return _run(() async {
      await repository.updatePhone(phone.trim());
      // Reload current user to update the local session state
      user = await repository.currentUser();
    });
  }

  Future<bool> deleteAccount() async {
    return _run(() async {
      await repository.deleteAccount();
      user = null;
    });
  }

  Future<bool> changePassword({String? currentPassword, required String newPassword}) async {
    return _run(() async {
      await repository.changePassword(
        currentPassword: currentPassword != null && currentPassword.isNotEmpty ? _hashPassword(currentPassword) : null,
        newPassword: _hashPassword(newPassword),
      );
      user = await repository.currentUser();
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    fieldErrors = {};
    notifyListeners();
    try {
      await action();
      loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      if (e.errors != null) {
        for (var err in e.errors!) {
          final field = err['field']?.toString();
          final msg = err['message']?.toString();
          if (field != null && msg != null) {
            fieldErrors[field] = msg;
          }
        }
      }
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
