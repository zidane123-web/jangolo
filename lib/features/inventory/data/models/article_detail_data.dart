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
