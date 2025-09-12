// lib/features/sales/data/models/sale_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_line_entity.dart';

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id,
    required super.customerId,
    super.customerName,
    required super.status,
    required super.createdAt,
    required super.items,
    super.globalDiscount,
    super.shippingFees,
    super.otherFees,
  });

  factory SaleModel.fromEntity(SaleEntity entity) {
    return SaleModel(
      id: entity.id,
      customerId: entity.customerId,
      customerName: entity.customerName,
      status: entity.status,
      createdAt: entity.createdAt,
      items: entity.items,
      globalDiscount: entity.globalDiscount,
      shippingFees: entity.shippingFees,
      otherFees: entity.otherFees,
    );
  }

  factory SaleModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleModel(
      id: doc.id,
      customerId: data['customer_id'] as String? ?? '',
      customerName: data['customer_name'] as String?,
      status: SaleStatus.values.byName(data['status'] as String),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      items: const <SaleLineEntity>[],
      globalDiscount: (data['global_discount'] as num?)?.toDouble() ?? 0.0,
      shippingFees: (data['shipping_fees'] as num?)?.toDouble() ?? 0.0,
      otherFees: (data['other_fees'] as num?)?.toDouble() ?? 0.0,
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
    };
  }
}
