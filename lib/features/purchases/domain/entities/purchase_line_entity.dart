// lib/features/purchases/domain/entities/purchase_line_entity.dart

// L'enum est maintenant dans un fichier partagé pour être accessible partout.
enum DiscountType { none, percent, fixed }

class PurchaseLineEntity {
  final String id; // L'identifiant unique de la ligne
  final String name;
  final String? sku;
  final double qty;
  final double unitPrice;
  final DiscountType discountType;
  final double discountValue; // % si percent, montant si fixed
  final double vatRate; // ex: 0.18 pour 18%

  const PurchaseLineEntity({
    required this.id,
    required this.name,
    this.sku,
    required this.qty,
    required this.unitPrice,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    this.vatRate = 0.18,
  });

  // Logique métier directement dans l'entité
  double get gross => qty * unitPrice;

  double get lineDiscount {
    switch (discountType) {
      case DiscountType.none:
        return 0;
      case DiscountType.percent:
        // Calcul de la remise en pourcentage
        return gross * (discountValue / 100.0);
      case DiscountType.fixed:
        // La remise fixe ne peut pas dépasser le montant total
        return discountValue.clamp(0, gross).toDouble();
    }
  }

  double get lineSubtotal => (gross - lineDiscount).clamp(0, double.infinity);
  double get lineTax => lineSubtotal * vatRate;
  double get lineTotal => lineSubtotal + lineTax;
}