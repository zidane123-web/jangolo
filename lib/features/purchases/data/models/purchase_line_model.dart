// lib/features/purchases/data/models/purchase_line_model.dart

import '../../domain/entities/purchase_line_entity.dart';

class PurchaseLineModel extends PurchaseLineEntity {
  // ✅ --- CONSTRUCTEUR MIS À JOUR ---
  const PurchaseLineModel({
    required super.id,
    required super.name,
    super.sku,
    required super.scannedCodeGroups,
    required super.unitPrice,
    super.discountType,
    super.discountValue,
    required super.vatRate, // Le champ est maintenant requis ici aussi
  });

  factory PurchaseLineModel.fromEntity(PurchaseLineEntity entity) {
    return PurchaseLineModel(
      id: entity.id,
      name: entity.name,
      sku: entity.sku,
      scannedCodeGroups: entity.scannedCodeGroups,
      unitPrice: entity.unitPrice,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      vatRate: entity.vatRate, // On passe la valeur
    );
  }

  factory PurchaseLineModel.fromJson(Map<String, dynamic> json, String id) {
    final groupsFromJson = (json['scanned_code_groups'] as List<dynamic>?)
        ?.map((group) => List<String>.from(group as List))
        .toList() ?? [];

    return PurchaseLineModel(
      id: id,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      scannedCodeGroups: groupsFromJson,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountType: DiscountType.values.byName(json['discount_type'] as String),
      discountValue: (json['discount_value'] as num).toDouble(),
      // On s'assure de lire la TVA depuis Firestore.
      // Pas de valeur par défaut, car elle est attendue.
      vatRate: (json['vat_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'scanned_code_groups': scannedCodeGroups,
      'unit_price': unitPrice,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'vat_rate': vatRate, // On sauvegarde la TVA
    };
  }
}