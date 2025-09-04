// lib/features/purchases/data/models/purchase_line_model.dart

// ➜ CORRECTION: Le chemin est maintenant correct.
import '../../domain/entities/purchase_line_entity.dart';

class PurchaseLineModel extends PurchaseLineEntity {
  const PurchaseLineModel({
    required super.id,
    required super.name,
    super.sku,
    required super.qty,
    required super.unitPrice,
    super.discountType,
    super.discountValue,
    super.vatRate,
  });

  factory PurchaseLineModel.fromEntity(PurchaseLineEntity entity) {
    return PurchaseLineModel(
      id: entity.id,
      name: entity.name,
      sku: entity.sku,
      qty: entity.qty,
      unitPrice: entity.unitPrice,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      vatRate: entity.vatRate,
    );
  }

  factory PurchaseLineModel.fromJson(Map<String, dynamic> json, String id) {
    return PurchaseLineModel(
      id: id,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      qty: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountType: DiscountType.values.byName(json['discount_type'] as String),
      discountValue: (json['discount_value'] as num).toDouble(),
      vatRate: (json['vat_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'quantity': qty,
      'unit_price': unitPrice,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'vat_rate': vatRate,
    };
  }
}