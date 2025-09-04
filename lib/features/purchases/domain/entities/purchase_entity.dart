// lib/features/purchases/domain/entities/purchase_entity.dart

import 'payment_entity.dart';
import 'purchase_line_entity.dart';

// Enum pour les statuts, maintenant dans la couche domain
enum PurchaseStatus { draft, approved, sent, partial, received, invoiced, paid }

class PurchaseEntity {
  final String id; // ID du bon de commande (ex: PO-1001)
  final String supplier;
  final PurchaseStatus status;
  final DateTime createdAt;
  final DateTime eta; // Estimated Time of Arrival
  final String warehouse;
  final List<PurchaseLineEntity> items;
  final List<PaymentEntity> payments; // <-- CHAMP AJOUTÉ

  // Champs optionnels
  final String? reference;
  final String? paymentTerms;
  final String? notes;

  // Frais et remises globaux
  final double globalDiscount; // Montant fixe
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
    this.payments = const [], // <-- Valeur par défaut
    this.reference,
    this.paymentTerms,
    this.notes,
    this.globalDiscount = 0.0,
    this.shippingFees = 0.0,
    this.otherFees = 0.0,
  });

  // --- Logique Métier ---

  // Calcul du sous-total de toutes les lignes
  double get subTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineSubtotal);

  // Calcul du total des remises (lignes + globale)
  double get discountTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineDiscount) + globalDiscount;

  // Base taxable après toutes les remises
  double get taxableBase => (subTotal - globalDiscount).clamp(0, double.infinity);

  // Calcul de la TVA totale
  double get taxTotal {
    if (items.isEmpty) return 0.0;
    final commonVatRate = items.first.vatRate;
    return taxableBase * commonVatRate;
  }

  // Calcul du total général
  double get grandTotal => taxableBase + taxTotal + shippingFees + otherFees;

  // --- Logique de paiement (NOUVEAU) ---

  // Calcule le montant total déjà payé pour cet achat
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);

  // Calcule le solde restant à payer
  double get balanceDue => grandTotal - totalPaid;

  // Vérifie si la commande est entièrement payée
  bool get isFullyPaid => balanceDue <= 0.01; // Marge d'erreur pour les calculs de double

  // --- Fin de la logique de paiement ---

  // Helper pour savoir si une commande est en retard
  bool get isLate =>
      status != PurchaseStatus.paid &&
      status != PurchaseStatus.received &&
      eta.isBefore(DateTime.now());
}