// lib/features/sales/data/models/sale_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sale_entity.dart';

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id,
    super.invoiceNumber,
    required super.customerId,
    super.customerName,
    required super.warehouseId,
    required super.warehouseName,
    required super.status,
    required super.createdAt,
    super.items,
    super.payments,
    super.globalDiscount,
    super.shippingFees,
    super.otherFees,
    super.createdBy,
    super.createdByName, // ✅ Ajouté
    super.hasDelivery,
    super.notes,
    required super.grandTotal, // ✅ Ajouté
  });

  factory SaleModel.fromEntity(SaleEntity entity) {
    return SaleModel(
      id: entity.id,
      invoiceNumber: entity.invoiceNumber,
      customerId: entity.customerId,
      customerName: entity.customerName,
      warehouseId: entity.warehouseId,
      warehouseName: entity.warehouseName,
      status: entity.status,
      createdAt: entity.createdAt,
      items: entity.items,
      payments: entity.payments,
      globalDiscount: entity.globalDiscount,
      shippingFees: entity.shippingFees,
      otherFees: entity.otherFees,
      createdBy: entity.createdBy,
      createdByName: entity.createdByName, // ✅ Ajouté
      hasDelivery: entity.hasDelivery,
      notes: entity.notes,
      grandTotal: entity.grandTotal, // ✅ Ajouté
    );
  }

  factory SaleModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleModel(
      id: doc.id,
      invoiceNumber: data['invoice_number'] as String?,
      customerId: data['customer_id'] as String? ?? '',
      customerName: data['customer_name'] as String?,
      warehouseId: data['warehouse_id'] as String? ?? '',
      warehouseName: data['warehouse_name'] as String? ?? '',
      status: SaleStatus.values.byName(data['status'] as String? ?? 'draft'),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      items: const [],
      payments: const [],
      globalDiscount: (data['global_discount'] as num?)?.toDouble() ?? 0.0,
      shippingFees: (data['shipping_fees'] as num?)?.toDouble() ?? 0.0,
      otherFees: (data['other_fees'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['created_by'] as String?,
      createdByName: data['created_by_name'] as String?, // ✅ Lecture du nom
      hasDelivery: data['has_delivery'] as bool?,
      notes: data['notes'] as String?,
      grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0.0, // ✅ Lecture du total
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'global_discount': globalDiscount,
      'shipping_fees': shippingFees,
      'other_fees': otherFees,
      'created_by': createdBy,
      'created_by_name': createdByName, // ✅ Écriture du nom
      'has_delivery': hasDelivery,
      'notes': notes,
      'grand_total': grandTotal, // ✅ Écriture du total
      'total_paid': totalPaid,
      'payment_status': paymentStatus.name,
    };
  }
}