import 'package:flutter/material.dart';

import '../../../settings/domain/entities/management_entities.dart';
import '../../models/payment_view_model.dart';

Future<PaymentViewModel?> showAddPaymentDialog({
  required BuildContext context,
  required String currency,
  required double grandTotal,
  required List<PaymentViewModel> existingPayments,
  required List<PaymentMethod> paymentMethods,
}) async {
  final totalPaidSoFar =
      existingPayments.fold(0.0, (total, p) => total + p.amount);
  final amountController = TextEditingController();
  PaymentMethod? selectedMethod =
      paymentMethods.isNotEmpty ? paymentMethods.first : null;
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<PaymentViewModel>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Ajouter un paiement'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Montant',
                  suffixText: currency,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final parsed = double.tryParse(v) ?? 0;
                  if (parsed <= 0) return 'Montant invalide';
                  if (parsed > grandTotal - totalPaidSoFar) {
                    return 'Dépasse le solde';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Moyen de paiement',
                  border: OutlineInputBorder(),
                ),
                items: paymentMethods
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method.name),
                        ))
                    .toList(),
                onChanged: (v) => selectedMethod = v,
                validator: (v) => v == null ? 'Requis' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  PaymentViewModel(
                    amount: double.parse(amountController.text),
                    method: selectedMethod!.name,
                  ),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      );
    },
  );

  amountController.dispose();
  return result;
}
