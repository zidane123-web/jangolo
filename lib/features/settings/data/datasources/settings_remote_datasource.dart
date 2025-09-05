// lib/features/settings/data/datasources/settings_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/management_models.dart';

abstract class SettingsRemoteDataSource {
  Future<List<SupplierModel>> getSuppliers(String organizationId);
  Future<List<WarehouseModel>> getWarehouses(String organizationId);
  Future<List<PaymentMethodModel>> getPaymentMethods(String organizationId);

  // Nouvelle méthode pour ajouter un fournisseur à Firestore
  Future<SupplierModel> addSupplier(String organizationId, String name);
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
      // Dans une vraie app, on utiliserait un logger
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
  Future<SupplierModel> addSupplier(String organizationId, String name) async {
    try {
      final docRef = await firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('suppliers')
          .add({'name': name, 'contact': null, 'phone': null}); // On ajoute le document avec des champs par défaut

      // On récupère le document fraîchement créé pour avoir son ID
      final doc = await docRef.get();
      return SupplierModel.fromSnapshot(doc);
    } catch (e) {
      print('Error adding supplier: $e');
      throw Exception('Could not add supplier');
    }
  }
}
