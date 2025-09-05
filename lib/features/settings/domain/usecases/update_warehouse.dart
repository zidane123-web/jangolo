// lib/features/settings/domain/usecases/update_warehouse.dart

import '../entities/management_entities.dart';
import '../repositories/settings_repository.dart';

class UpdateWarehouse {
  final SettingsRepository repository;
  UpdateWarehouse(this.repository);

  Future<void> call({
    required String organizationId,
    required Warehouse warehouse,
  }) {
    return repository.updateWarehouse(
      organizationId: organizationId,
      warehouse: warehouse,
    );
  }
}