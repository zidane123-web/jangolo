import 'package:flutter/material.dart';

import '../../models/payment_view_model.dart';
import '../../models/reception_status_choice.dart';
import 'payment_and_reception_step.dart';

class PaymentAndReceptionStepWrapper extends StatelessWidget {
  final double grandTotal;
  final String currency;
  final List<PaymentViewModel> payments;
  final VoidCallback onAddPayment;
  final ValueChanged<int> onRemovePayment;
  final ReceptionStatusChoice receptionStatus;
  final ValueChanged<ReceptionStatusChoice> onReceptionStatusChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const PaymentAndReceptionStepWrapper({
    super.key,
    required this.grandTotal,
    required this.currency,
    required this.payments,
    required this.onAddPayment,
    required this.onRemovePayment,
    required this.receptionStatus,
    required this.onReceptionStatusChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PaymentAndReceptionStep(
            grandTotal: grandTotal,
            currency: currency,
            payments: payments,
            onAddPayment: onAddPayment,
            onRemovePayment: onRemovePayment,
            receptionStatus: receptionStatus,
            onReceptionStatusChanged: onReceptionStatusChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              OutlinedButton(onPressed: onBack, child: const Text('Retour')),
              const Spacer(),
              FilledButton(onPressed: onNext, child: const Text('Suivant')),
            ],
          ),
        ),
      ],
    );
  }
}
