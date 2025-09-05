// lib/features/purchases/domain/entities/purchase_line_entity.dart

enum DiscountType { none, percent, fixed }

class PurchaseLineEntity {
  final String id;
  final String name;
  final String? sku;
  
  // ✅ La liste de codes devient une liste de groupes de codes.
  final List<List<String>> scannedCodeGroups;

  final double unitPrice;
  final DiscountType discountType;
  final double discountValue;
  final double vatRate;

  const PurchaseLineEntity({
    required this.id,
    required this.name,
    this.sku,
    required this.scannedCodeGroups, // Le constructeur est mis à jour
    required this.unitPrice,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    this.vatRate = 0.18,
  });

  // La quantité est maintenant le nombre de groupes.
  double get qty => scannedCodeGroups.length.toDouble();

  // Le reste de la logique ne change pas
  double get gross => qty * unitPrice;

  double get lineDiscount {
    switch (discountType) {
      case DiscountType.none:
        return 0;
      case DiscountType.percent:
        return gross * (discountValue / 100.0);
      case DiscountType.fixed:
        return discountValue.clamp(0, gross).toDouble();
    }
  }

  double get lineSubtotal => (gross - lineDiscount).clamp(0, double.infinity);
  double get lineTax => lineSubtotal * vatRate;
  double get lineTotal => lineSubtotal + lineTax;
}