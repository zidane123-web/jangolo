// lib/features/purchases/data/models/purchase_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// ➜ CORRECTION: Les chemins sont maintenant corrects et les imports inutiles sont supprimés.
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
    return PurchaseModel(
      id: doc.id,
      supplier: data['supplier'] as String,
      status: PurchaseStatus.values.byName(data['status'] as String),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      eta: (data['eta'] as Timestamp).toDate(),
      warehouse: data['warehouse'] as String,
      // Note: les items et payments sont dans des sous-collections,
      // ils seront chargés séparément. La liste est donc initialement vide.
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
      'supplier': supplier,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'eta': Timestamp.fromDate(eta),
      'warehouse': warehouse,
      'reference': reference,
      'payment_terms': paymentTerms,
      'notes': notes,
      'global_discount': globalDiscount,
      'shipping_fees': shippingFees,
      'other_fees': otherFees,
      // On ne sauvegarde pas 'items' et 'payments' ici car ce sont des sous-collections.
      // Le `grandTotal` est calculé, pas stocké, pour éviter la redondance.
    };
  }
}