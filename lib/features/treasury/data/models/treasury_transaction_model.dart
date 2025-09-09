// lib/features/treasury/data/models/treasury_transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/treasury_transaction.dart';

class TreasuryTransactionModel extends TreasuryTransaction {
  const TreasuryTransactionModel({
    required super.id,
    required super.date,
    required super.amount,
    required super.paymentMethodId,
    required super.paymentMethodName,
    required super.type,
    super.relatedDocumentId,
    required super.userId,
  });

  factory TreasuryTransactionModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TreasuryTransactionModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      paymentMethodId: data['paymentMethodId'] ?? '',
      paymentMethodName: data['paymentMethodName'] ?? '',
      type: data['type'] ?? '',
      relatedDocumentId: data['relatedDocumentId'] as String?,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'type': type,
      'relatedDocumentId': relatedDocumentId,
      'userId': userId,
    };
  }
}
