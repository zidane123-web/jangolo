// lib/features/sales/domain/entities/sale_entity.dart

import 'payment_entity.dart';
import 'sale_line_entity.dart';

/// Possible states for a sale.
enum SaleStatus { draft, completed, cancelled }
enum PaymentStatus { unpaid, partial, paid }

class SaleEntity {
  final String id;
  final String? invoiceNumber;
  final String customerId;
  final String? customerName;
  final String warehouseId;
  final String warehouseName;
  final SaleStatus status;
  final DateTime createdAt;
  final List<SaleLineEntity> items;
  final List<PaymentEntity> payments;
  final double globalDiscount;
  final double shippingFees;
  final double otherFees;

  final String? createdBy; // Contient l'ID de l'utilisateur
  final String? createdByName; // ✅ NOUVEAU: Contient le nom de l'utilisateur

  final bool? hasDelivery;
  final String? notes;

  // ✅ MODIFIÉ: Le grand total est maintenant un champ final pour être stocké.
  final double grandTotal;


  const SaleEntity({
    required this.id,
    this.invoiceNumber,
    required this.customerId,
    this.customerName,
    required this.warehouseId,
    required this.warehouseName,
    this.status = SaleStatus.draft,
    required this.createdAt,
    this.items = const [],
    this.payments = const [],
    this.globalDiscount = 0.0,
    this.shippingFees = 0.0,
    this.otherFees = 0.0,
    this.createdBy,
    this.createdByName, // ✅ Ajouté au constructeur
    this.hasDelivery,
    this.notes,
    required this.grandTotal, // ✅ Requis dans le constructeur
  });
  
  // ✅ La logique de paiement utilise maintenant le champ grandTotal
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get balanceDue => grandTotal - totalPaid;

  PaymentStatus get paymentStatus {
    if (totalPaid <= 0.01) return PaymentStatus.unpaid;
    if (balanceDue > 0.01) return PaymentStatus.partial;
    return PaymentStatus.paid;
  }
}