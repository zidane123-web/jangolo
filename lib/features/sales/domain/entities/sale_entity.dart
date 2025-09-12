// lib/features/sales/domain/entities/sale_entity.dart

import 'payment_entity.dart';
import 'sale_line_entity.dart';

/// Possible states for a sale.
enum SaleStatus { draft, completed, cancelled }
enum PaymentStatus { unpaid, partial, paid }

class SaleEntity {
  final String id;
  final String customerId;
  final String? customerName;
  final SaleStatus status;
  final DateTime createdAt;
  final List<SaleLineEntity> items;
  final List<PaymentEntity> payments; // ✅ CHAMP AJOUTÉ
  final double globalDiscount;
  final double shippingFees;
  final double otherFees;
  
  final String? createdBy;
  
  // ✅ CHAMP AJOUTÉ POUR LA GESTION DES LIVRAISONS
  final bool? hasDelivery;


  const SaleEntity({
    required this.id,
    required this.customerId,
    this.customerName,
    this.status = SaleStatus.draft,
    required this.createdAt,
    this.items = const [],
    this.payments = const [], // ✅ Ajouté au constructeur
    this.globalDiscount = 0.0,
    this.shippingFees = 0.0,
    this.otherFees = 0.0,
    this.createdBy,
    this.hasDelivery,
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

  // ✅ LOGIQUE DE PAIEMENT AMÉLIORÉE
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get balanceDue => grandTotal - totalPaid;

  PaymentStatus get paymentStatus {
    if (totalPaid <= 0.01) return PaymentStatus.unpaid;
    if (balanceDue > 0.01) return PaymentStatus.partial;
    return PaymentStatus.paid;
  }
}
