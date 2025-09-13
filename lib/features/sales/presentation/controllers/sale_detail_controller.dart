import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../settings/domain/entities/management_entities.dart';
import '../../../treasury/data/models/treasury_transaction_model.dart';
import '../../data/models/payment_model.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/sale_entity.dart';
import '../models/payment_view_model.dart';

class SaleDetailController {
  final FirebaseFirestore _firestore;

  SaleDetailController(this._firestore);

  Future<void> addPayment({
    required String organizationId,
    required SaleEntity sale,
    required PaymentViewModel payment,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');

    await _firestore.runTransaction((transaction) async {
      // --- 1. LECTURES ---
      // On lit les méthodes de paiement pour mettre à jour les soldes.
      final Map<String, DocumentSnapshot> methodSnapshots = {};

      if (!methodSnapshots.containsKey(payment.methodIn.id)) {
        final ref = _firestore
            .collection('organisations')
            .doc(organizationId)
            .collection('paymentMethods')
            .doc(payment.methodIn.id);
        methodSnapshots[payment.methodIn.id] = await transaction.get(ref);
      }
      if (payment.change > 0 && !methodSnapshots.containsKey(payment.methodOut.id)) {
        final ref = _firestore
            .collection('organisations')
            .doc(organizationId)
            .collection('paymentMethods')
            .doc(payment.methodOut.id);
        methodSnapshots[payment.methodOut.id] = await transaction.get(ref);
      }

      // --- 2. ÉCRITURES ---
      final saleRef = _firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('sales')
          .doc(sale.id);

      // 2a. Ajout du paiement dans la sous-collection
      final paymentEntity = PaymentEntity(
        id: const Uuid().v4(),
        amount: payment.amountPaid,
        date: DateTime.now(),
        paymentMethod: payment.methodIn,
      );
      final paymentModel = PaymentModel.fromEntity(paymentEntity);
      final paymentRef = saleRef.collection('payments').doc(paymentModel.id);
      transaction.set(paymentRef, paymentModel.toJson());

      // 2b. Mise à jour du document de vente principal
      final newTotalPaid = sale.totalPaid + payment.amountPaid;
      final newBalance = sale.grandTotal - newTotalPaid;
      final newStatus =
          newBalance <= 0.01 ? PaymentStatus.paid : PaymentStatus.partial;

      transaction.update(saleRef, {
        'total_paid': newTotalPaid,
        'payment_status': newStatus.name,
      });

      // 2c. Mise à jour de la trésorerie et des soldes
      _updateTreasuryAndBalances(
        transaction: transaction,
        organizationId: organizationId,
        saleId: sale.id,
        payment: payment,
        methodSnapshots: methodSnapshots,
        currentUser: currentUser,
      );
    });
  }

  void _updateTreasuryAndBalances({
    required FirebaseTransaction transaction,
    required String organizationId,
    required String saleId,
    required PaymentViewModel payment,
    required Map<String, DocumentSnapshot> methodSnapshots,
    required User currentUser,
  }) {
    if (payment.isSimplePayment) {
      // Cas simple: 1 transaction, 1 mise à jour de solde
      final ref = methodSnapshots[payment.methodIn.id]!.reference;
      transaction.update(ref, {'balance': FieldValue.increment(payment.amountPaid)});

      final treasuryRef = _firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('treasury_transactions')
          .doc();
      final tx = TreasuryTransactionModel(
        id: treasuryRef.id,
        date: DateTime.now(),
        amount: payment.amountPaid,
        paymentMethodId: payment.methodIn.id,
        paymentMethodName: payment.methodIn.name,
        type: 'sale_receipt',
        relatedDocumentId: saleId,
        userId: currentUser.uid,
      );
      transaction.set(treasuryRef, tx.toJson());
    } else {
      // Cas complexe: 2 transactions, 2 mises à jour de solde (encaissement + rendu monnaie)
      // Entrée d'argent
      final refIn = methodSnapshots[payment.methodIn.id]!.reference;
      transaction.update(refIn, {'balance': FieldValue.increment(payment.amountGiven)});
      final treasuryRefIn = _firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('treasury_transactions')
          .doc();
      final txIn = TreasuryTransactionModel(
        id: treasuryRefIn.id,
        date: DateTime.now(),
        amount: payment.amountGiven,
        paymentMethodId: payment.methodIn.id,
        paymentMethodName: payment.methodIn.name,
        type: 'sale_receipt',
        relatedDocumentId: saleId,
        userId: currentUser.uid,
      );
      transaction.set(treasuryRefIn, txIn.toJson());

      // Sortie d'argent (monnaie)
      final refOut = methodSnapshots[payment.methodOut.id]!.reference;
      transaction.update(refOut, {'balance': FieldValue.increment(-payment.change)});
      final treasuryRefOut = _firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('treasury_transactions')
          .doc();
      final txOut = TreasuryTransactionModel(
        id: treasuryRefOut.id,
        date: DateTime.now(),
        amount: -payment.change,
        paymentMethodId: payment.methodOut.id,
        paymentMethodName: payment.methodOut.name,
        type: 'sale_change',
        relatedDocumentId: saleId,
        userId: currentUser.uid,
      );
      transaction.set(treasuryRefOut, txOut.toJson());
    }
  }
}

