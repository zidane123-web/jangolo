// lib/features/sales/domain/entities/sale_line_entity.dart

/// Represents how a discount is applied to a sale line.
enum DiscountType { none, percent, fixed }

class SaleLineEntity {
  final String id;
  final String productId;
  final String? name;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final DiscountType discountType;
  final double discountValue;
  final double vatRate;
  // Indicates whether the item is tracked by serial number
  final bool isSerialized;
  // List of scanned serial codes for serialized items
  final List<String> scannedCodes;

  const SaleLineEntity({
    required this.id,
    required this.productId,
    this.name,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    this.vatRate = 0.0,
    this.isSerialized = false,
    this.scannedCodes = const [],
  });

  double get gross => quantity * unitPrice;

  double get lineDiscount {
    switch (discountType) {
      case DiscountType.none:
        return 0.0;
      case DiscountType.percent:
        return gross * (discountValue / 100.0);
      case DiscountType.fixed:
        return discountValue.clamp(0, gross);
    }
  }

  double get lineSubtotal => (gross - lineDiscount).clamp(0, double.infinity);
  double get lineTax => lineSubtotal * vatRate;
  double get lineTotal => lineSubtotal + lineTax;
  double get lineMargin => lineSubtotal - (quantity * costPrice);
}
