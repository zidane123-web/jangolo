// lib/features/treasury/domain/entities/treasury_transaction.dart

class TreasuryTransaction {
  final String id;
  final DateTime date;
  final double amount; // négatif pour sortie, positif pour entrée
  final String paymentMethodId;
  final String paymentMethodName;
  final String type; // ex: 'purchase_payment', 'sale_receipt', 'adjustment'
  final String? relatedDocumentId; // ex: ID de l'achat lié
  final String userId;

  const TreasuryTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.type,
    this.relatedDocumentId,
    required this.userId,
  });
}
