// lib/features/sales/presentation/widgets/create_sale/add_payment_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../settings/domain/entities/management_entities.dart';
import '../../models/payment_view_model.dart';

Future<PaymentViewModel?> showAddPaymentDialog({
  required BuildContext context,
  required double amountDue,
  required List<PaymentMethod> paymentMethods,
}) {
  return showModalBottomSheet<PaymentViewModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _AddPaymentDialogContent(
        amountDue: amountDue,
        paymentMethods: paymentMethods,
      );
    },
  );
}

class _AddPaymentDialogContent extends StatefulWidget {
  final double amountDue;
  final List<PaymentMethod> paymentMethods;

  const _AddPaymentDialogContent({
    required this.amountDue,
    required this.paymentMethods,
  });

  @override
  State<_AddPaymentDialogContent> createState() =>
      _AddPaymentDialogContentState();
}

class _AddPaymentDialogContentState extends State<_AddPaymentDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  PaymentMethod? _selectedMethod;
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethods.isNotEmpty) {
      _selectedMethod = widget.paymentMethods.first;
    }
    _amountCtrl.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_calculateChange);
    _amountCtrl.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final given = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (given > widget.amountDue) {
      setState(() => _change = given - widget.amountDue);
    } else {
      setState(() => _change = 0.0);
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner un moyen de paiement.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final amountGiven = double.tryParse(_amountCtrl.text) ?? 0.0;
    final amountToPay = (_change > 0) ? widget.amountDue : amountGiven;

    final result = PaymentViewModel(
      amountPaid: amountToPay,
      method: _selectedMethod!,
      amountGiven: amountGiven,
    );
    Navigator.of(context).pop(result);
  }

  String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ajouter un paiement', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Solde restant à payer : ${_money(widget.amountDue)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Montant reçu du client *',
                  suffixText: 'F CFA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if ((double.tryParse(v) ?? 0) <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _amountCtrl.text = widget.amountDue.toStringAsFixed(0);
                  },
                  child: const Text('Saisir le montant exact'),
                ),
              ),
              if (_change > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Monnaie à rendre : ${_money(_change)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Payé via *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.paymentMethods
                    .map((method) => ChoiceChip(
                          label: Text(method.name),
                          selected: _selectedMethod?.id == method.id,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedMethod = method);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ajouter le paiement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
