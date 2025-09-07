// lib/features/inventory/data/models/article.dart

// Modèle pour les données d'un article, maintenant réutilisable.
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

// Enum pour les catégories, maintenant réutilisable.
enum ArticleCategory { phones, accessories, tablets, wearables }
