import 'package:flutter/material.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';

class AddressViewModel extends ChangeNotifier {
  final AddressRepository repository;
  AddressViewModel(this.repository);

  List<Address> addresses = [];
  Address? selectedAddress;
  bool loading = false;
  String? error;

  Future<void> loadAddresses() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      addresses = await repository.getMyAddresses();
      Address? defaultAddress;
      for (final address in addresses) {
        if (address.isDefault) {
          defaultAddress = address;
          break;
        }
      }
      selectedAddress = defaultAddress ?? (addresses.isNotEmpty ? addresses.first : null);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  void select(Address address) {
    selectedAddress = address;
    notifyListeners();
  }

  Future<Address?> createAddress({
    required String label,
    required String addressLine,
    required double latitude,
    required double longitude,
    bool isDefault = true,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final address = await repository.createAddress(
        label: label,
        addressLine: addressLine,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      addresses = [address, ...addresses.where((a) => a.id != address.id)];
      selectedAddress = address;
      loading = false;
      notifyListeners();
      return address;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteAddress(String id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.deleteAddress(id);
      addresses = addresses.where((a) => a.id != id).toList();
      if (selectedAddress?.id == id) {
        selectedAddress = addresses.isNotEmpty ? addresses.first : null;
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
}
