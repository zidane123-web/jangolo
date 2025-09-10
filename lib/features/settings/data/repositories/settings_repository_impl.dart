// lib/features/settings/data/repositories/settings_repository_impl.dart

import '../../domain/entities/management_entities.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/management_models.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Supplier>> getSuppliers(String organizationId) async {
    return remoteDataSource.getSuppliers(organizationId);
  }

  @override
  Future<List<Warehouse>> getWarehouses(String organizationId) async {
    return remoteDataSource.getWarehouses(organizationId);
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String organizationId) async {
    // ✅ CORRECTION APPLIQUÉE ICI
    // On s'assure de convertir les modèles en entités.
    final models = await remoteDataSource.getPaymentMethods(organizationId);
    return models.map((model) => model as PaymentMethod).toList();
  }

  @override
  Future<Supplier> addSupplier({required String organizationId, required String name, String? phone}) {
    return remoteDataSource.addSupplier(organizationId, name, phone);
  }

  // ✅ IMPLÉMENTATION DES NOUVELLES MÉTHODES
  @override
  Future<Warehouse> addWarehouse({required String organizationId, required String name, String? address}) {
    return remoteDataSource.addWarehouse(organizationId, name, address);
  }

  @override
  Future<void> updateWarehouse({required String organizationId, required Warehouse warehouse}) {
    final warehouseModel = WarehouseModel(id: warehouse.id, name: warehouse.name, address: warehouse.address);
    return remoteDataSource.updateWarehouse(organizationId, warehouseModel);
  }

  @override
  Future<void> deleteWarehouse({required String organizationId, required String warehouseId}) {
    return remoteDataSource.deleteWarehouse(organizationId, warehouseId);
  }

  // --- Payment Methods CRUD ---
  @override
  Future<PaymentMethod> addPaymentMethod({
    required String organizationId,
    required String name,
    required String type,
    required double initialBalance, // 👈 CORRECTION ICI
  }) {
    return remoteDataSource.addPaymentMethod(organizationId, name, type, initialBalance);
  }

  @override
  Future<void> updatePaymentMethod({required String organizationId, required PaymentMethod method}) {
    final model = PaymentMethodModel(
      id: method.id,
      name: method.name,
      type: method.type,
      balance: method.balance,
    );
    return remoteDataSource.updatePaymentMethod(organizationId, model);
  }

  @override
  Future<void> deletePaymentMethod({required String organizationId, required String methodId}) {
    return remoteDataSource.deletePaymentMethod(organizationId, methodId);
  }
}