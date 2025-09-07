import 'package:flutter/material.dart';

import '../../../../settings/domain/entities/management_entities.dart';
import '../../models/payment_view_model.dart';

Future<PaymentViewModel?> showAddPaymentDialog({
  required BuildContext context,
  required String currency,
  required double grandTotal,
  required List<PaymentViewModel> existingPayments,
  required List<PaymentMethod> paymentMethods,
}) {
  return showDialog<PaymentViewModel>(
    context: context,
    builder: (context) {
      return _AddPaymentDialogContent(
        currency: currency,
        grandTotal: grandTotal,
        existingPayments: existingPayments,
        paymentMethods: paymentMethods,
      );
    },
  );
}

// ✅ Nouveau widget interne pour gérer l'état du dialogue
class _AddPaymentDialogContent extends StatefulWidget {
  final String currency;
  final double grandTotal;
  final List<PaymentViewModel> existingPayments;
  final List<PaymentMethod> paymentMethods;

  const _AddPaymentDialogContent({
    required this.currency,
    required this.grandTotal,
    required this.existingPayments,
    required this.paymentMethods,
  });

  @override
  State<_AddPaymentDialogContent> createState() =>
      _AddPaymentDialogContentState();
}

class _AddPaymentDialogContentState extends State<_AddPaymentDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  PaymentMethod? _selectedMethod;
  late final double _totalPaidSoFar;

  @override
  void initState() {
    super.initState();
    // Le contrôleur est créé ici
    _amountController = TextEditingController();
    _totalPaidSoFar =
        widget.existingPayments.fold(0.0, (total, p) => total + p.amount);
    if (widget.paymentMethods.isNotEmpty) {
      _selectedMethod = widget.paymentMethods.first;
    }
  }

  @override
  void dispose() {
    // Le contrôleur est détruit proprement par le framework ici
    _amountController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (_formKey.currentState!.validate()) {
      final payment = PaymentViewModel(
        amount: double.parse(_amountController.text),
        method: _selectedMethod!.name,
      );
      Navigator.pop(context, payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un paiement'),
      // ✅ Ajout du SingleChildScrollView pour éviter le "RenderFlex overflow"
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant',
                  suffixText: widget.currency,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final parsed = double.tryParse(v) ?? 0;
                  if (parsed <= 0) return 'Montant invalide';
                  // Petite marge de 0.01 pour les erreurs de virgule flottante
                  if (parsed > (widget.grandTotal - _totalPaidSoFar) + 0.01) {
                    return 'Dépasse le solde';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Moyen de paiement',
                  border: OutlineInputBorder(),
                ),
                items: widget.paymentMethods
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMethod = v),
                validator: (v) => v == null ? 'Requis' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _onAdd,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}