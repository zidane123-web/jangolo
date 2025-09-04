// lib/features/purchases/domain/entities/payment_entity.dart

class PaymentEntity {
  final String id; // L'identifiant unique du paiement
  final double amount; // Le montant payé
  final DateTime date; // La date du paiement
  final String paymentMethod; // ex: 'Espèces', 'Virement', 'Chèque', 'Mobile Money'
  final String treasuryAccountId; // L'ID du compte de trésorerie utilisé
  final String? reference; // Référence de la transaction (ex: N° de chèque, ID de transaction)

  const PaymentEntity({
    required this.id,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.treasuryAccountId,
    this.reference,
  });
}