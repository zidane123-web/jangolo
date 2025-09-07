import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/article_entity.dart';

class ArticleModel extends ArticleEntity {
  const ArticleModel({
    required super.id,
    required super.name,
    required super.category,
    required super.buyPrice,
    required super.sellPrice,
    required super.hasSerializedUnits,
    required super.totalQuantity,
    required super.createdAt,
  });

  factory ArticleModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final categoryString = data['category'] as String? ?? 'accessories';
    final category = ArticleCategory.values.firstWhere(
      (e) => e.name == categoryString,
      orElse: () => ArticleCategory.accessories,
    );

    return ArticleModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Nom non défini',
      category: category,
      buyPrice: (data['buyPrice'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (data['sellPrice'] as num?)?.toDouble() ?? 0.0,
      hasSerializedUnits: data['hasSerializedUnits'] as bool? ?? false,
      totalQuantity: (data['totalQuantity'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}
