// lib/features/purchases/data/models/purchase_line_model.dart

import '../../domain/entities/purchase_line_entity.dart';

class PurchaseLineModel extends PurchaseLineEntity {
  // ✅ --- CONSTRUCTEUR CORRIGÉ ---
  const PurchaseLineModel({
    required super.id,
    required super.name,
    super.sku,
    required super.scannedCodeGroups, // Correction du nom ici
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
      scannedCodeGroups: entity.scannedCodeGroups, // Correction du nom ici
      unitPrice: entity.unitPrice,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      vatRate: entity.vatRate,
    );
  }

  factory PurchaseLineModel.fromJson(Map<String, dynamic> json, String id) {
    // La conversion depuis une liste de listes doit être explicite
    final groupsFromJson = (json['scanned_code_groups'] as List<dynamic>?)
        ?.map((group) => List<String>.from(group as List))
        .toList() ?? [];

    return PurchaseLineModel(
      id: id,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      scannedCodeGroups: groupsFromJson, // Correction du nom ici
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
      'scanned_code_groups': scannedCodeGroups, // Correction du nom ici
      'unit_price': unitPrice,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'vat_rate': vatRate,
    };
  }
}