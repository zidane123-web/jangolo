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

  ArticleEntity copyWith({
    String? id,
    String? name,
    ArticleCategory? category,
    double? buyPrice,
    double? sellPrice,
    bool? hasSerializedUnits,
    int? totalQuantity,
    DateTime? createdAt,
  }) {
    return ArticleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      hasSerializedUnits: hasSerializedUnits ?? this.hasSerializedUnits,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
