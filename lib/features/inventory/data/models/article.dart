// Modèle pour les données d'un article, utilisé dans plusieurs écrans.
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

// Données spécifiques pour la page de détail.
class ArticleDetailData {
  final String name;
  final String sku;
  final String categoryLabel;
  final double buyPrice;
  final double sellPrice;
  final int qty;

  const ArticleDetailData({
    required this.name,
    required this.sku,
    required this.categoryLabel,
    required this.buyPrice,
    required this.sellPrice,
    required this.qty,
  });
}