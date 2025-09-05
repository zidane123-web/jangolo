// lib/features/purchases/presentation/models/payment_view_model.dart

// Un modèle simple pour gérer un paiement dans l'UI avant la sauvegarde.
class PaymentViewModel {
  final double amount;
  final String method;

  const PaymentViewModel({
    required this.amount,
    required this.method,
  });
}