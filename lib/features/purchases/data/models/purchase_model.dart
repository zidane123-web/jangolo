// lib/features/purchases/data/models/purchase_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../settings/domain/entities/management_entities.dart';
import '../../domain/entities/purchase_entity.dart';

class PurchaseModel extends PurchaseEntity {
  const PurchaseModel({
    required super.id,
    required super.supplier,
    required super.status,
    required super.createdAt,
    required super.eta,
    required super.warehouse,
    required super.items,
    required super.payments,
    super.reference,
    super.paymentTerms,
    super.notes,
    super.globalDiscount,
    super.shippingFees,
    super.otherFees,
  });

  factory PurchaseModel.fromEntity(PurchaseEntity entity) {
    return PurchaseModel(
      id: entity.id,
      supplier: entity.supplier,
      status: entity.status,
      createdAt: entity.createdAt,
      eta: entity.eta,
      warehouse: entity.warehouse,
      items: entity.items,
      payments: entity.payments,
      reference: entity.reference,
      paymentTerms: entity.paymentTerms,
      notes: entity.notes,
      globalDiscount: entity.globalDiscount,
      shippingFees: entity.shippingFees,
      otherFees: entity.otherFees,
    );
  }

  factory PurchaseModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // ✅ --- CORRECTION: Gère à la fois l'ancien (String) et le nouveau (Map) format ---
    late final Supplier supplier;
    if (data['supplier'] is Map) {
      final supplierData = data['supplier'] as Map<String, dynamic>;
      supplier = Supplier(id: supplierData['id'] ?? '', name: supplierData['name'] ?? 'N/A');
    } else {
      // Gère les anciennes données où le fournisseur était juste un nom
      supplier = Supplier(id: '', name: data['supplier'] as String? ?? 'N/A');
    }

    late final Warehouse warehouse;
    if (data['warehouse'] is Map) {
      final warehouseData = data['warehouse'] as Map<String, dynamic>;
      warehouse = Warehouse(id: warehouseData['id'] ?? '', name: warehouseData['name'] ?? 'N/A');
    } else {
      // Gère les anciennes données où l'entrepôt était juste un nom
      warehouse = Warehouse(id: '', name: data['warehouse'] as String? ?? 'N/A');
    }

    return PurchaseModel(
      id: doc.id,
      supplier: supplier,
      status: PurchaseStatus.values.byName(data['status'] as String),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      eta: (data['eta'] as Timestamp).toDate(),
      warehouse: warehouse,
      items: const [],
      payments: const [],
      reference: data['reference'] as String?,
      paymentTerms: data['payment_terms'] as String?,
      notes: data['notes'] as String?,
      globalDiscount: (data['global_discount'] as num?)?.toDouble() ?? 0.0,
      shippingFees: (data['shipping_fees'] as num?)?.toDouble() ?? 0.0,
      otherFees: (data['other_fees'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplier': {'id': supplier.id, 'name': supplier.name},
      'warehouse': {'id': warehouse.id, 'name': warehouse.name},
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'eta': Timestamp.fromDate(eta),
      'reference': reference,
      'payment_terms': paymentTerms,
      'notes': notes,
      'global_discount': globalDiscount,
      'shipping_fees': shippingFees,
      'other_fees': otherFees,
    };
  }
}