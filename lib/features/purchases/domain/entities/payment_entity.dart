// lib/features/purchases/domain/entities/payment_entity.dart

import '../../../settings/domain/entities/management_entities.dart'; // ✅ NOUVEL IMPORT

class PaymentEntity {
  final String id;
  final double amount;
  final DateTime date;
  // ✅ MODIFICATION: On utilise l'objet PaymentMethod
  final PaymentMethod paymentMethod;
  final String? reference;

  const PaymentEntity({
    required this.id,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.reference,
  });
}