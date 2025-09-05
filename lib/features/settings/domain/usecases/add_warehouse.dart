// lib/features/settings/domain/usecases/add_warehouse.dart

import '../entities/management_entities.dart';
import '../repositories/settings_repository.dart';

class AddWarehouse {
  final SettingsRepository repository;
  AddWarehouse(this.repository);

  Future<Warehouse> call({
    required String organizationId,
    required String name,
    String? address,
  }) {
    return repository.addWarehouse(
      organizationId: organizationId,
      name: name,
      address: address,
    );
  }
}