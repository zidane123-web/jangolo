// lib/features/settings/domain/usecases/delete_warehouse.dart

import '../repositories/settings_repository.dart';

class DeleteWarehouse {
  final SettingsRepository repository;
  DeleteWarehouse(this.repository);

  Future<void> call({
    required String organizationId,
    required String warehouseId,
  }) {
    return repository.deleteWarehouse(
      organizationId: organizationId,
      warehouseId: warehouseId,
    );
  }
}