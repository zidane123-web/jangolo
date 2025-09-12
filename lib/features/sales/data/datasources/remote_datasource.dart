// lib/features/sales/data/datasources/remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_line_model.dart';
import '../models/sale_model.dart';

abstract class SalesRemoteDataSource {
  Stream<List<SaleModel>> getAllSales(String organizationId);
  Future<void> createSale(String organizationId, SaleModel sale);
  Future<(SaleModel?, List<SaleLineModel>)> getSaleDetails(
      String organizationId, String saleId);
  Future<void> updateSale(String organizationId, SaleModel sale);
}

class SalesRemoteDataSourceImpl implements SalesRemoteDataSource {
  final FirebaseFirestore firestore;

  SalesRemoteDataSourceImpl({required this.firestore});

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
}
