// lib/features/purchases/domain/entities/purchase_entity.dart

import '../../../settings/domain/entities/management_entities.dart'; // ✅ NOUVEL IMPORT
import 'payment_entity.dart';
import 'purchase_line_entity.dart';

// Enum pour les statuts, maintenant dans la couche domain
enum PurchaseStatus { draft, approved, sent, partial, received, invoiced, paid }

class PurchaseEntity {
  final String id;
  // ✅ MODIFICATION: On utilise maintenant l'objet Supplier
  final Supplier supplier;
  final PurchaseStatus status;
  final DateTime createdAt;
  final DateTime eta; // Estimated Time of Arrival
  // ✅ MODIFICATION: On utilise maintenant l'objet Warehouse
  final Warehouse warehouse;
  final List<PurchaseLineEntity> items;
  final List<PaymentEntity> payments;

  // Champs optionnels
  final String? reference;
  final String? paymentTerms;
  final String? notes;

  // Frais et remises globaux
  final double globalDiscount;
  final double shippingFees;
  final double otherFees;

  const PurchaseEntity({
    required this.id,
    required this.supplier,
    required this.status,
    required this.createdAt,
    required this.eta,
    required this.warehouse,
    required this.items,
    this.payments = const [],
    this.reference,
    this.paymentTerms,
    this.notes,
    this.globalDiscount = 0.0,
    this.shippingFees = 0.0,
    this.otherFees = 0.0,
  });

  // --- Logique Métier (inchangée) ---
  double get subTotal => items.fold(0.0, (sum, item) => sum + item.lineSubtotal);
  double get discountTotal => items.fold(0.0, (sum, item) => sum + item.lineDiscount) + globalDiscount;
  double get taxableBase => (subTotal - globalDiscount).clamp(0, double.infinity);
  double get taxTotal {
    if (items.isEmpty) return 0.0;
    final commonVatRate = items.first.vatRate;
    return taxableBase * commonVatRate;
  }
  double get grandTotal => taxableBase + taxTotal + shippingFees + otherFees;
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get balanceDue => grandTotal - totalPaid;
  bool get isFullyPaid => balanceDue <= 0.01;
  bool get isLate => status != PurchaseStatus.paid && status != PurchaseStatus.received && eta.isBefore(DateTime.now());
}