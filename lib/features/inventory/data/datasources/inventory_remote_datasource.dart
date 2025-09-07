import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/article_model.dart';

abstract class InventoryRemoteDataSource {
  Stream<List<ArticleModel>> getArticles(String organizationId);
  Future<ArticleModel> addArticle(String organizationId, ArticleModel article);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore firestore;

  InventoryRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<ArticleModel>> getArticles(String organizationId) {
    try {
      final snapshots = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('inventory')
          .orderBy('createdAt', descending: true)
          .snapshots();

      return snapshots.map((snapshot) {
        return snapshot.docs
            .map((doc) => ArticleModel.fromSnapshot(doc))
            .toList();
      });
    } catch (e) {
      // In a real application, use a logger
      print('Erreur lors de la récupération des articles: $e');
      throw Exception('Impossible de charger les articles.');
    }
  }

  @override
  Future<ArticleModel> addArticle(String organizationId, ArticleModel article) async {
    try {
      final col = firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('inventory');

      final docRef = await col.add(article.toMap());
      return ArticleModel(
        id: docRef.id,
        name: article.name,
        category: article.category,
        buyPrice: article.buyPrice,
        sellPrice: article.sellPrice,
        hasSerializedUnits: article.hasSerializedUnits,
        totalQuantity: article.totalQuantity,
        createdAt: article.createdAt,
      );
    } catch (e) {
      print('Erreur lors de la création de l\'article: $e');
      throw Exception('Impossible de créer l\'article.');
    }
  }
}
