import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/address.dart';
import '../data/address_repository.dart';

/// Contrôleur CRUD des adresses du client.
///
/// Expose la liste sous forme d'`AsyncValue<List<Address>>` et recharge après
/// chaque mutation pour rester aligné sur le serveur (source de vérité pour
/// `isDefault`).
class AddressesController extends AsyncNotifier<List<Address>> {
  AddressRepository get _repo => ref.read(addressRepositoryProvider);

  @override
  Future<List<Address>> build() => _repo.list();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  /// Crée une adresse puis recharge la liste.
  Future<void> create(AddressRequest request) async {
    await _repo.create(request);
    await refresh();
  }

  /// Met à jour une adresse puis recharge la liste.
  Future<void> updateAddress(String id, AddressRequest request) async {
    await _repo.update(id, request);
    await refresh();
  }

  /// Supprime une adresse puis recharge la liste.
  Future<void> deleteAddress(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}

final addressesControllerProvider =
    AsyncNotifierProvider<AddressesController, List<Address>>(
      AddressesController.new,
    );
