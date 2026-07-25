import '../entities/address.dart';

abstract class AddressRepository {
  Future<List<Address>> getMyAddresses();
  Future<Address> createAddress({
    required String label,
    required String addressLine,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  });
  Future<void> deleteAddress(String id);
}
