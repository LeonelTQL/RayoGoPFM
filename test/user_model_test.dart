import 'package:flutter_test/flutter_test.dart';
import 'package:pry_proyecto_final_delivery/data/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    const userJson = {
      'id': 'user-123',
      'name': 'Leonel',
      'email': 'leonel@example.com',
      'phone': '1234567',
      'role': 'cliente',
      'avatarUrl': 'http://avatar.url',
      'hasPassword': true,
    };

    test('should parse from json correctly', () {
      final user = UserModel.fromJson(userJson);
      expect(user.id, 'user-123');
      expect(user.name, 'Leonel');
      expect(user.email, 'leonel@example.com');
      expect(user.phone, '1234567');
      expect(user.role, 'cliente');
      expect(user.avatarUrl, 'http://avatar.url');
      expect(user.hasPassword, true);
      expect(user.isClient, true);
      expect(user.isAdmin, false);
      expect(user.isDelivery, false);
    });

    test('should serialize to json correctly', () {
      const user = UserModel(
        id: 'user-123',
        name: 'Leonel',
        email: 'leonel@example.com',
        phone: '1234567',
        role: 'cliente',
        avatarUrl: 'http://avatar.url',
        hasPassword: true,
      );
      final json = user.toJson();
      expect(json['id'], 'user-123');
      expect(json['name'], 'Leonel');
      expect(json['email'], 'leonel@example.com');
      expect(json['phone'], '1234567');
      expect(json['role'], 'cliente');
      expect(json['avatarUrl'], 'http://avatar.url');
      expect(json['hasPassword'], true);
    });

    test('copyWith works correctly', () {
      const user = UserModel(
        id: 'user-123',
        name: 'Leonel',
        email: 'leonel@example.com',
        phone: '1234567',
        role: 'cliente',
      );
      final updated = user.copyWith(name: 'Leonel Update', role: 'admin');
      expect(updated.name, 'Leonel Update');
      expect(updated.role, 'admin');
      expect(updated.email, 'leonel@example.com');
    });
  });
}
