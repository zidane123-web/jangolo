// lib/features/inventory/data/models/article.dart

import '../../domain/entities/article_entity.dart';

// Simplified model for purchase flows.
class Article {
  final ArticleCategory category;
  final String name;
  final String sku;
  final double buyPrice;
  final double sellPrice;
  final int qty;

  const Article({
    required this.category,
    required this.name,
    required this.sku,
    required this.buyPrice,
    required this.sellPrice,
    required this.qty,
  });
}
