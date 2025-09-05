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
    return remoteDataSource.getPaymentMethods(organizationId);
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
}