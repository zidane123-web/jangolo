// lib/features/settings/domain/repositories/settings_repository.dart

import '../entities/management_entities.dart';

abstract class SettingsRepository {
  Future<List<Supplier>> getSuppliers(String organizationId);
  Future<List<Warehouse>> getWarehouses(String organizationId);
  Future<List<PaymentMethod>> getPaymentMethods(String organizationId);

  Future<Supplier> addSupplier({required String organizationId, required String name, String? phone});

  // ✅ NOUVELLES MÉTHODES POUR LES ENTREPÔTS
  Future<Warehouse> addWarehouse({required String organizationId, required String name, String? address});
  Future<void> updateWarehouse({required String organizationId, required Warehouse warehouse});
  Future<void> deleteWarehouse({required String organizationId, required String warehouseId});

  // ✅ CRUD pour les moyens de paiement
  Future<PaymentMethod> addPaymentMethod({required String organizationId, required String name, required String type, required double initialBalance}); // 👈 CORRECTION ICI
  Future<void> updatePaymentMethod({required String organizationId, required PaymentMethod method});
  Future<void> deletePaymentMethod({required String organizationId, required String methodId});
}