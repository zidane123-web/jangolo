// lib/features/sales/data/models/sale_line_model.dart

import '../../domain/entities/sale_line_entity.dart';

class SaleLineModel extends SaleLineEntity {
  const SaleLineModel({
    required super.id,
    required super.productId,
    super.name,
    required super.quantity,
    required super.unitPrice,
    required super.costPrice,
    super.discountType,
    super.discountValue,
    super.vatRate,
    super.isSerialized,
    super.scannedCodes,
  });

  factory SaleLineModel.fromEntity(SaleLineEntity entity) {
    return SaleLineModel(
      id: entity.id,
      productId: entity.productId,
      name: entity.name,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      costPrice: entity.costPrice,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      vatRate: entity.vatRate,
      isSerialized: entity.isSerialized,
      scannedCodes: entity.scannedCodes,
    );
  }

  factory SaleLineModel.fromJson(Map<String, dynamic> json, String id) {
    return SaleLineModel(
      id: id,
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      discountType:
          DiscountType.values.byName(json['discount_type'] as String? ?? 'none'),
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      vatRate: (json['vat_rate'] as num?)?.toDouble() ?? 0.0,
      isSerialized: json['is_serialized'] as bool? ?? false,
      scannedCodes: List<String>.from(json['scanned_codes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'vat_rate': vatRate,
      'is_serialized': isSerialized,
      'scanned_codes': scannedCodes,
    };
  }
}
