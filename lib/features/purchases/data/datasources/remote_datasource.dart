// lib/features/purchases/data/datasources/remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_line_model.dart';
import '../models/purchase_model.dart';

abstract class PurchaseRemoteDataSource {
  Stream<List<PurchaseModel>> getAllPurchases(String organizationId);
  
  // ➜ Nouvelle méthode ajoutée au contrat
  Future<void> createPurchase(String organizationId, PurchaseModel purchase);
}

class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final FirebaseFirestore firestore;

  PurchaseRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<PurchaseModel>> getAllPurchases(String organizationId) {
    try {
      final snapshots = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('purchases')
          .orderBy('created_at', descending: true)
          .snapshots();

      return snapshots.map((snapshot) {
        return snapshot.docs
            .map((doc) => PurchaseModel.fromSnapshot(doc))
            .toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des achats: $e');
      throw Exception('Impossible de charger les achats.');
    }
  }

  // ➜ Implémentation de la logique de création
  @override
  Future<void> createPurchase(String organizationId, PurchaseModel purchase) async {
    try {
      final purchaseCollection = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('purchases');

      // On utilise une transaction "batch" pour s'assurer que soit tout,
      // soit rien n'est écrit en base de données. C'est plus sûr.
      final batch = firestore.batch();

      // 1. On crée le document principal de l'achat
      final purchaseRef = purchaseCollection.doc(purchase.id);
      batch.set(purchaseRef, purchase.toJson());

      // 2. On crée un document pour chaque ligne d'article dans la sous-collection "items"
      for (final item in purchase.items) {
        final itemRef = purchaseRef.collection('items').doc(); // Firestore génère l'ID
        final itemModel = PurchaseLineModel.fromEntity(item);
        batch.set(itemRef, itemModel.toJson());
      }
      
      // On exécute toutes les opérations d'un coup
      await batch.commit();
      
    } catch (e) {
      print('Erreur lors de la création de l\'achat: $e');
      throw Exception('Impossible de sauvegarder l\'achat.');
    }
  }
}