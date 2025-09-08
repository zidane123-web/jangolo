// lib/features/purchases/data/models/purchase_line_model.dart

import '../../domain/entities/purchase_line_entity.dart';

class PurchaseLineModel extends PurchaseLineEntity {
  const PurchaseLineModel({
    required super.id,
    required super.name,
    super.sku,
    required super.scannedCodeGroups,
    required super.unitPrice,
    super.discountType,
    super.discountValue,
    required super.vatRate,
    required super.allocatedShipping,
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
      vatRate: entity.vatRate,
      allocatedShipping: entity.allocatedShipping,
    );
  }

  factory PurchaseLineModel.fromJson(Map<String, dynamic> json, String id) {
    // ✅ --- CORRECTION POUR LA LECTURE ---
    // On lit maintenant un Map et on le transforme en List<List<String>>
    final groupsFromJson = <List<String>>[];
    if (json['scanned_code_groups'] is Map) {
      final groupsMap = json['scanned_code_groups'] as Map<String, dynamic>;
      // On trie les clés pour s'assurer que l'ordre est conservé
      final sortedKeys = groupsMap.keys.toList()..sort();
      for (final key in sortedKeys) {
        if (groupsMap[key] is List) {
          groupsFromJson.add(List<String>.from(groupsMap[key]));
        }
      }
    }

    return PurchaseLineModel(
      id: id,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      scannedCodeGroups: groupsFromJson,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountType: DiscountType.values.byName(json['discount_type'] as String),
      discountValue: (json['discount_value'] as num).toDouble(),
      vatRate: (json['vat_rate'] as num).toDouble(),
      allocatedShipping: (json['allocated_shipping'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    // ✅ --- CORRECTION POUR L'ÉCRITURE ---
    // On transforme la List<List<String>> en Map<String, dynamic>
    final Map<String, dynamic> groupsToSave = {
      for (int i = 0; i < scannedCodeGroups.length; i++)
        'group_$i': scannedCodeGroups[i],
    };

    return {
      'name': name,
      'sku': sku,
      'scanned_code_groups': groupsToSave, // On sauvegarde le Map
      'unit_price': unitPrice,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'vat_rate': vatRate,
      'allocated_shipping': allocatedShipping,
    };
  }
}
