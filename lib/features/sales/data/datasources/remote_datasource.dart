// lib/features/sales/data/datasources/remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';
import '../models/sale_line_model.dart';
import '../models/sale_model.dart';

abstract class SalesRemoteDataSource {
  Stream<List<SaleModel>> getAllSales(String organizationId);
  Future<void> createSale(String organizationId, SaleModel sale);
  Future<(SaleModel?, List<SaleLineModel>)> getSaleDetails(
      String organizationId, String saleId);
  Future<void> updateSale(String organizationId, SaleModel sale);

  // --- NEW CLIENT METHODS ---
  Stream<List<ClientModel>> getClients(String organizationId);
  Future<ClientModel> addClient(String organizationId, ClientModel client);
}

class SalesRemoteDataSourceImpl implements SalesRemoteDataSource {
  final FirebaseFirestore firestore;

  SalesRemoteDataSourceImpl({required this.firestore});

  // Helper générique pour un stream de collection
  Stream<List<T>> _getCollectionStream<T>({
    required String organizationId,
    required String collectionName,
    required T Function(DocumentSnapshot) fromSnapshot,
  }) {
    try {
      final snapshots = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection(collectionName)
          .snapshots();
      return snapshots.map((snapshot) {
        return snapshot.docs.map(fromSnapshot).toList();
      });
    } catch (e) {
      throw Exception('Impossible de charger la collection $collectionName.');
    }
  }

  @override
  Stream<List<SaleModel>> getAllSales(String organizationId) {
    try {
      final snapshots = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('sales')
          .orderBy('created_at', descending: true)
          .snapshots();

      return snapshots.map((snapshot) {
        return snapshot.docs.map((doc) => SaleModel.fromSnapshot(doc)).toList();
      });
    } catch (e) {
      throw Exception('Impossible de charger les ventes.');
    }
  }

  @override
  Future<void> createSale(String organizationId, SaleModel sale) async {
    try {
      final salesCollection = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('sales');

      final batch = firestore.batch();
      final saleRef = salesCollection.doc(sale.id);
      batch.set(saleRef, sale.toJson());

      for (final item in sale.items) {
        final itemRef = saleRef.collection('items').doc();
        final itemModel = SaleLineModel.fromEntity(item);
        batch.set(itemRef, itemModel.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Impossible de sauvegarder la vente.');
    }
  }

  @override
  Future<(SaleModel?, List<SaleLineModel>)> getSaleDetails(
      String organizationId, String saleId) async {
    final saleRef = firestore
        .collection('organisations')
        .doc(organizationId)
        .collection('sales')
        .doc(saleId);

    final saleDoc = await saleRef.get();
    if (!saleDoc.exists) {
      return (null, <SaleLineModel>[]);
    }

    final itemsSnapshot = await saleRef.collection('items').get();
    final items = itemsSnapshot.docs
        .map((doc) => SaleLineModel.fromJson(doc.data(), doc.id))
        .toList();

    final sale = SaleModel.fromSnapshot(saleDoc);
    return (sale, items);
  }

  @override
  Future<void> updateSale(String organizationId, SaleModel sale) async {
    try {
      final saleRef = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('sales')
          .doc(sale.id);

      await saleRef.update(sale.toJson());
    } catch (e) {
      throw Exception('Impossible de mettre à jour la vente.');
    }
  }

  // --- IMPLEMENTATION OF NEW CLIENT METHODS ---
  @override
  Stream<List<ClientModel>> getClients(String organizationId) {
    return _getCollectionStream(
      organizationId: organizationId,
      collectionName: 'clients',
      fromSnapshot: (doc) => ClientModel.fromSnapshot(doc),
    );
  }

  @override
  Future<ClientModel> addClient(
      String organizationId, ClientModel client) async {
    try {
      final docRef = await firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('clients')
          .add(client.toJson());

      final doc = await docRef.get();
      return ClientModel.fromSnapshot(doc);
    } catch (e) {
      throw Exception('Impossible d\'ajouter le client.');
    }
  }
}
