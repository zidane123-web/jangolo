// lib/features/sales/presentation/controllers/create_sale_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../inventory/data/models/movement_model.dart';
import '../../../inventory/domain/entities/movement_entity.dart';
import '../../../treasury/data/models/treasury_transaction_model.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../domain/usecases/create_sale.dart';
import '../models/payment_view_model.dart';

/// Handles business logic for the Create Sale screen.
class CreateSaleController {
  final CreateSale _createSale;
  final FirebaseFirestore _firestore;

  CreateSaleController(SalesRepository repository, this._firestore)
      : _createSale = CreateSale(repository);

  Future<void> saveSale({
    required String organizationId,
    required SaleEntity sale,
    required List<PaymentViewModel> payments,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');

    await _firestore.runTransaction((transaction) async {
      // --- 1. LECTURES ---
      // On lit les articles pour vérifier les stocks et les mettre à jour.
      final Map<String, DocumentSnapshot> articleSnapshots = {};
      for (final item in sale.items) {
        final ref = _firestore
            .collection('organisations')
            .doc(organizationId)
            .collection('inventory')
            .doc(item.productId);
        articleSnapshots[item.productId] = await transaction.get(ref);
      }

      // On lit les méthodes de paiement pour mettre à jour les soldes.
      final Map<String, DocumentSnapshot> methodSnapshots = {};
      for (final p in payments) {
        if (!methodSnapshots.containsKey(p.methodIn.id)) {
          final ref = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('paymentMethods')
              .doc(p.methodIn.id);
          methodSnapshots[p.methodIn.id] = await transaction.get(ref);
        }
        if (p.change > 0 && !methodSnapshots.containsKey(p.methodOut.id)) {
          final ref = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('paymentMethods')
              .doc(p.methodOut.id);
          methodSnapshots[p.methodOut.id] = await transaction.get(ref);
        }
      }

      // --- 2. ÉCRITURES ---
      // 2a. Sauvegarde de la vente (document principal et sous-collections)
      await _createSale(organizationId: organizationId, sale: sale);

      // 2b. Mise à jour des stocks et création des mouvements
      for (final line in sale.items) {
        final ref = articleSnapshots[line.productId]!.reference;
        transaction.update(ref, {
          'totalQuantity': FieldValue.increment(-line.quantity),
        });

        final movement = MovementModel(
          id: '', // Firestore generates it
          type: MovementType.out,
          qty: line.quantity.toInt(),
          date: sale.createdAt,
          reason: 'Vente #${sale.id}',
          userId: currentUser.uid,
          sourceDocument: sale.id,
        );
        final movementRef = ref.collection('movements').doc();
        transaction.set(movementRef, movement.toMap());
      }

      // 2c. Mise à jour de la trésorerie
      for (final payment in payments) {
        if (payment.isSimplePayment) {
          // Cas simple: 1 transaction, 1 mise à jour de solde
          final ref = methodSnapshots[payment.methodIn.id]!.reference;
          transaction.update(ref, {
            'balance': FieldValue.increment(payment.amountPaid)
          });

          final treasuryRef = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('treasury_transactions')
              .doc();
          final tx = TreasuryTransactionModel(
            id: treasuryRef.id,
            date: sale.createdAt,
            amount: payment.amountPaid,
            paymentMethodId: payment.methodIn.id,
            paymentMethodName: payment.methodIn.name,
            type: 'sale_receipt',
            relatedDocumentId: sale.id,
            userId: currentUser.uid,
          );
          transaction.set(treasuryRef, tx.toJson());
        } else {
          // Cas complexe: 2 transactions, 2 mises à jour de solde
          // Entrée d'argent
          final refIn = methodSnapshots[payment.methodIn.id]!.reference;
          transaction.update(refIn, {
            'balance': FieldValue.increment(payment.amountGiven)
          });
          final treasuryRefIn = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('treasury_transactions')
              .doc();
          final txIn = TreasuryTransactionModel(
            id: treasuryRefIn.id,
            date: sale.createdAt,
            amount: payment.amountGiven,
            paymentMethodId: payment.methodIn.id,
            paymentMethodName: payment.methodIn.name,
            type: 'sale_receipt',
            relatedDocumentId: sale.id,
            userId: currentUser.uid,
          );
          transaction.set(treasuryRefIn, txIn.toJson());

          // Sortie d'argent (monnaie)
          final refOut = methodSnapshots[payment.methodOut.id]!.reference;
          transaction.update(refOut, {
            'balance': FieldValue.increment(-payment.change)
          });
          final treasuryRefOut = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('treasury_transactions')
              .doc();
          final txOut = TreasuryTransactionModel(
            id: treasuryRefOut.id,
            date: sale.createdAt,
            amount: -payment.change,
            paymentMethodId: payment.methodOut.id,
            paymentMethodName: payment.methodOut.name,
            type: 'sale_change',
            relatedDocumentId: sale.id,
            userId: currentUser.uid,
          );
          transaction.set(treasuryRefOut, txOut.toJson());
        }
      }
    });
  }
}

