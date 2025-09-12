// lib/features/sales/presentation/models/payment_view_model.dart

import '../../../settings/domain/entities/management_entities.dart';

/// Un modèle simple pour gérer un paiement dans l'UI avant la sauvegarde.
class PaymentViewModel {
  final double amountPaid; // Ce que le client doit payer pour cette transaction
  final PaymentMethod method;
  final double? amountGiven; // Montant physiquement donné par le client

  const PaymentViewModel({
    required this.amountPaid,
    required this.method,
    this.amountGiven,
  });

  // Calcule la monnaie à rendre
  double get change => (amountGiven ?? amountPaid) - amountPaid;
}
