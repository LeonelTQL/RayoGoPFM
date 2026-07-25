import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasource/remote/api_client.dart';
import '../models/address_model.dart';

class AddressRepositoryImpl implements AddressRepository {
  final ApiClient apiClient;
  AddressRepositoryImpl(this.apiClient);

  @override
  Future<List<Address>> getMyAddresses() async {
    final json = await apiClient.get('/addresses');
    return (json['addresses'] as List<dynamic>)
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Address> createAddress({
    required String label,
    required String addressLine,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    final json = await apiClient.post('/addresses', {
      'label': label,
      'addressLine': addressLine,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    });
    return AddressModel.fromJson(json['address'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAddress(String id) async {
    await apiClient.delete('/addresses/$id');
  }
}
