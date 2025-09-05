// lib/features/settings/domain/repositories/settings_repository.dart

import '../entities/management_entities.dart';

abstract class SettingsRepository {
  Future<List<Supplier>> getSuppliers(String organizationId);
  Future<List<Warehouse>> getWarehouses(String organizationId);
  Future<List<PaymentMethod>> getPaymentMethods(String organizationId);

  // ✅ NOUVELLE MÉTHODE
  Future<Supplier> addSupplier({required String organizationId, required String name});
}