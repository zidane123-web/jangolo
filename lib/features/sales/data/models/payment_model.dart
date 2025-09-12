// lib/features/sales/data/models/payment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../settings/data/models/management_models.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.amount,
    required super.date,
    required super.paymentMethod,
    super.reference,
  }) : super(paymentMethod: paymentMethod);

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      amount: entity.amount,
      date: entity.date,
      paymentMethod: entity.paymentMethod,
      reference: entity.reference,
    );
  }

  factory PaymentModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp).toDate(),
      paymentMethod: PaymentMethodModel.fromJson(data['payment_method']),
      reference: data['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'payment_method': PaymentMethodModel(
        id: paymentMethod.id,
        name: paymentMethod.name,
        type: paymentMethod.type,
        balance: paymentMethod.balance,
      ).toJson(),
      'reference': reference,
    };
  }
}
