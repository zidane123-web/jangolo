enum ArticleCategory { phones, accessories, tablets, wearables }

class ArticleEntity {
  final String id;
  final String name;
  final ArticleCategory category;
  final double buyPrice;
  final double sellPrice;
  final bool hasSerializedUnits;
  final int totalQuantity;
  final DateTime createdAt;

  const ArticleEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.buyPrice,
    required this.sellPrice,
    required this.hasSerializedUnits,
    required this.totalQuantity,
    required this.createdAt,
  });
}
