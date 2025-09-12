// lib/features/sales/data/models/sale_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sale_entity.dart';

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id,
    required super.customerId,
    super.customerName,
    required super.status,
    required super.createdAt,
    super.items,
    super.payments,
    super.globalDiscount,
    super.shippingFees,
    super.otherFees,
    super.createdBy,
    super.hasDelivery,
  });

  factory SaleModel.fromEntity(SaleEntity entity) {
    return SaleModel(
      id: entity.id,
      customerId: entity.customerId,
      customerName: entity.customerName,
      status: entity.status,
      createdAt: entity.createdAt,
      items: entity.items,
      payments: entity.payments,
      globalDiscount: entity.globalDiscount,
      shippingFees: entity.shippingFees,
      otherFees: entity.otherFees,
      createdBy: entity.createdBy,
      hasDelivery: entity.hasDelivery,
    );
  }

  factory SaleModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleModel(
      id: doc.id,
      customerId: data['customer_id'] as String? ?? '',
      customerName: data['customer_name'] as String?,
      status: SaleStatus.values.byName(data['status'] as String? ?? 'draft'),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      // Les listes (items, payments) sont chargées séparément via une sous-collection
      items: const [], 
      payments: const [],
      globalDiscount: (data['global_discount'] as num?)?.toDouble() ?? 0.0,
      shippingFees: (data['shipping_fees'] as num?)?.toDouble() ?? 0.0,
      otherFees: (data['other_fees'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['created_by'] as String?,
      hasDelivery: data['has_delivery'] as bool?,
      // ✅ Ajout des totaux calculés pour un accès facile
      // grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0.0,
      // totalPaid: (data['total_paid'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'global_discount': globalDiscount,
      'shipping_fees': shippingFees,
      'other_fees': otherFees,
      'created_by': createdBy,
      'has_delivery': hasDelivery,
      // ✅ Ajout des totaux et du statut de paiement dénormalisés
      'grand_total': grandTotal,
      'total_paid': totalPaid,
      'payment_status': paymentStatus.name,
    };
  }
}
