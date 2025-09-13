// lib/features/sales/presentation/models/payment_view_model.dart

import '../../../settings/domain/entities/management_entities.dart';

/// Un modèle pour gérer un paiement dans l'UI avant la sauvegarde.
class PaymentViewModel {
  /// Montant réellement dû pour cette transaction (ex: 13 500 F).
  final double amountPaid;

  /// Montant physiquement donné par le client (ex: 15 000 F).
  final double amountGiven;

  /// Méthode de paiement qui reçoit l'argent (ex: Caisse).
  final PaymentMethod methodIn;

  /// Méthode de paiement qui rend la monnaie (peut être identique à methodIn).
  final PaymentMethod methodOut;

  const PaymentViewModel({
    required this.amountPaid,
    required this.amountGiven,
    required this.methodIn,
    required this.methodOut,
  });

  /// Calcule la monnaie à rendre.
  double get change => amountGiven - amountPaid;

  /// Indique si c'est un paiement simple sans rendu de monnaie complexe.
  bool get isSimplePayment => change <= 0.01 || methodIn.id == methodOut.id;
}
