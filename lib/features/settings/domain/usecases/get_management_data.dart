// lib/features/settings/domain/usecases/get_management_data.dart

import '../entities/management_entities.dart';
import '../repositories/settings_repository.dart';

class GetSuppliers {
  final SettingsRepository repository;
  GetSuppliers(this.repository);

  Future<List<Supplier>> call(String organizationId) {
    return repository.getSuppliers(organizationId);
  }
}

class GetWarehouses {
  final SettingsRepository repository;
  GetWarehouses(this.repository);

  Future<List<Warehouse>> call(String organizationId) {
    return repository.getWarehouses(organizationId);
  }
}

class GetPaymentMethods {
  final SettingsRepository repository;
  GetPaymentMethods(this.repository);

  Future<List<PaymentMethod>> call(String organizationId) {
    return repository.getPaymentMethods(organizationId);
  }
}