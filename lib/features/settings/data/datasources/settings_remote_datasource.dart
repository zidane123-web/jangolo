// lib/features/settings/data/datasources/settings_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/management_models.dart';

abstract class SettingsRemoteDataSource {
  Future<List<SupplierModel>> getSuppliers(String organizationId);
  Future<List<WarehouseModel>> getWarehouses(String organizationId);
  Future<List<PaymentMethodModel>> getPaymentMethods(String organizationId);
  Future<SupplierModel> addSupplier(String organizationId, String name, String? phone);

  // ✅ NOUVELLES MÉTHODES POUR LES ENTREPÔTS
  Future<WarehouseModel> addWarehouse(String organizationId, String name, String? address);
  Future<void> updateWarehouse(String organizationId, WarehouseModel warehouse);
  Future<void> deleteWarehouse(String organizationId, String warehouseId);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore firestore;

  SettingsRemoteDataSourceImpl({required this.firestore});

  // Helper générique pour récupérer une collection
  Future<List<T>> _getCollection<T>({
    required String organizationId,
    required String collectionName,
    required T Function(DocumentSnapshot) fromSnapshot,
  }) async {
    try {
      final snapshot = await firestore
          .collection('organisations')
          .doc(organizationId)
          .collection(collectionName)
          .get();
      return snapshot.docs.map(fromSnapshot).toList();
    } catch (e) {
      print('Error fetching $collectionName: $e');
      throw Exception('Could not load $collectionName');
    }
  }

  @override
  Future<List<SupplierModel>> getSuppliers(String organizationId) async {
    return _getCollection(
      organizationId: organizationId,
      collectionName: 'suppliers',
      fromSnapshot: (doc) => SupplierModel.fromSnapshot(doc),
    );
  }

  @override
  Future<List<WarehouseModel>> getWarehouses(String organizationId) async {
    return _getCollection(
      organizationId: organizationId,
      collectionName: 'warehouses',
      fromSnapshot: (doc) => WarehouseModel.fromSnapshot(doc),
    );
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods(String organizationId) async {
    return _getCollection(
      organizationId: organizationId,
      collectionName: 'paymentMethods',
      fromSnapshot: (doc) => PaymentMethodModel.fromSnapshot(doc),
    );
  }

  @override
  Future<SupplierModel> addSupplier(String organizationId, String name, String? phone) async {
    try {
      final docRef = await firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('suppliers')
          .add({'name': name, 'contact': null, 'phone': phone});

      final doc = await docRef.get();
      return SupplierModel.fromSnapshot(doc);
    } catch (e) {
      print('Error adding supplier: $e');
      throw Exception('Could not add supplier');
    }
  }
  
  // ✅ IMPLÉMENTATION DES NOUVELLES MÉTHODES
  @override
  Future<WarehouseModel> addWarehouse(String organizationId, String name, String? address) async {
    try {
      final docRef = await firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('warehouses')
          .add({'name': name, 'address': address});

      final doc = await docRef.get();
      return WarehouseModel.fromSnapshot(doc);
    } catch (e) {
      print('Error adding warehouse: $e');
      throw Exception('Could not add warehouse');
    }
  }

  @override
  Future<void> updateWarehouse(String organizationId, WarehouseModel warehouse) async {
    try {
      final batch = firestore.batch();
      
      // 1. Mettre à jour le document principal de l'entrepôt
      final warehouseRef = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('warehouses')
          .doc(warehouse.id);
      batch.update(warehouseRef, warehouse.toJson());

      // 2. Mettre à jour les données dénormalisées dans les achats
      final purchasesSnapshot = await firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('purchases')
          .where('warehouse.id', isEqualTo: warehouse.id)
          .get();
      
      for (final doc in purchasesSnapshot.docs) {
        batch.update(doc.reference, {'warehouse': warehouse.toJson()});
      }

      await batch.commit();

    } catch (e) {
      print('Error updating warehouse: $e');
      throw Exception('Could not update warehouse');
    }
  }

  @override
  Future<void> deleteWarehouse(String organizationId, String warehouseId) async {
    try {
      // Pour la sécurité, on pourrait vérifier si l'entrepôt est utilisé
      // avant de le supprimer, mais pour l'instant on fait une suppression simple.
      await firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('warehouses')
          .doc(warehouseId)
          .delete();
    } catch (e) {
      print('Error deleting warehouse: $e');
      throw Exception('Could not delete warehouse');
    }
  }
}