// lib/features/purchases/presentation/widgets/create_purchase/payment_and_reception_step.dart

import 'package:flutter/material.dart';
import 'package:jangolo/features/purchases/presentation/screens/create_purchase_screen.dart';
import 'form_widgets.dart'; // Pour PickerField

// Nouveaux enums pour les choix de l'utilisateur
enum PaymentStatusChoice { notPaid, partiallyPaid, fullyPaid }

class PaymentAndReceptionStep extends StatelessWidget {
  // --- Callbacks et valeurs pour le statut de paiement ---
  final PaymentStatusChoice paymentStatus;
  final ValueChanged<PaymentStatusChoice> onPaymentStatusChanged;
  final TextEditingController partialAmountController;
  final String? paymentMethod;
  final VoidCallback onPaymentMethodTap;

  // --- Callbacks et valeurs pour le statut de réception ---
  final ReceptionStatusChoice receptionStatus;
  final ValueChanged<ReceptionStatusChoice> onReceptionStatusChanged;
  
  final String currency;

  const PaymentAndReceptionStep({
    super.key,
    required this.paymentStatus,
    required this.onPaymentStatusChanged,
    required this.partialAmountController,
    required this.paymentMethod,
    required this.onPaymentMethodTap,
    required this.receptionStatus,
    required this.onReceptionStatusChanged,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Statut du Paiement',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SegmentedButton<PaymentStatusChoice>(
            segments: const [
              ButtonSegment(value: PaymentStatusChoice.notPaid, label: Text('Non Payé')),
              ButtonSegment(value: PaymentStatusChoice.partiallyPaid, label: Text('Acompte')),
              ButtonSegment(value: PaymentStatusChoice.fullyPaid, label: Text('Payé')),
            ],
            selected: {paymentStatus},
            onSelectionChanged: (selection) => onPaymentStatusChanged(selection.first),
          ),
          
          // Affiche les champs supplémentaires si un paiement est effectué
          if (paymentStatus != PaymentStatusChoice.notPaid) ...[
            const SizedBox(height: 20),
            if (paymentStatus == PaymentStatusChoice.partiallyPaid)
              LabeledTextField(
                controller: partialAmountController,
                label: 'Montant de l\'acompte',
                prefixIcon: Icons.attach_money,
                hint: '0.00 $currency',
              ),
            const SizedBox(height: 16),
            PickerField(
              label: 'Compte de paiement *',
              value: paymentMethod ?? 'Sélectionner...',
              onTap: onPaymentMethodTap,
              prefixIcon: Icons.account_balance_wallet_outlined,
            ),
          ],
          
          const Divider(height: 48),

          Text(
            'Statut de la Réception',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ReceptionStatusChoice>(
            segments: const [
              ButtonSegment(
                value: ReceptionStatusChoice.toReceive,
                label: Text('À recevoir'),
                icon: Icon(Icons.local_shipping_outlined),
              ),
              ButtonSegment(
                value: ReceptionStatusChoice.alreadyReceived,
                label: Text('Déjà Reçu'),
                icon: Icon(Icons.inventory_2_outlined),
              ),
            ],
            selected: {receptionStatus},
            onSelectionChanged: (selection) => onReceptionStatusChanged(selection.first),
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}