// lib/features/sales/domain/entities/sale_entity.dart

import 'sale_line_entity.dart';

/// Possible states for a sale.
enum SaleStatus { draft, completed, cancelled }

class SaleEntity {
  final String id;
  final String customerId;
  final String? customerName;
  final SaleStatus status;
  final DateTime createdAt;
  final List<SaleLineEntity> items;
  final double globalDiscount;
  final double shippingFees;
  final double otherFees;
  
  final String? createdBy;
  final String? paymentStatus;
  
  // ✅ CHAMP AJOUTÉ POUR LA GESTION DES LIVRAISONS
  final bool? hasDelivery;


  const SaleEntity({
    required this.id,
    required this.customerId,
    this.customerName,
    this.status = SaleStatus.draft,
    required this.createdAt,
    this.items = const [],
    this.globalDiscount = 0.0,
    this.shippingFees = 0.0,
    this.otherFees = 0.0,
    this.createdBy,
    this.paymentStatus,
    this.hasDelivery, // ✅ Ajouté au constructeur
  });

  double get subTotal => items.fold(0.0, (sum, item) => sum + item.lineSubtotal);
  double get discountTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineDiscount) + globalDiscount;
  double get taxableBase =>
      (subTotal - globalDiscount).clamp(0, double.infinity);
  double get taxTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTax);
  double get grandTotal =>
      taxableBase + taxTotal + shippingFees + otherFees;
}