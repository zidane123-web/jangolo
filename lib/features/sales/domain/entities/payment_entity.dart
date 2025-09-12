// lib/features/sales/domain/entities/payment_entity.dart

import '../../../settings/domain/entities/management_entities.dart';

class PaymentEntity {
  final String id;
  final double amount;
  final DateTime date;
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
