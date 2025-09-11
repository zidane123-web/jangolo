import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../settings/domain/entities/management_entities.dart';
import '../../models/payment_view_model.dart';

Future<PaymentViewModel?> showAddPaymentBottomSheet({
  required BuildContext context,
  required String currency,
  required double grandTotal,
  required List<PaymentViewModel> existingPayments,
  required List<PaymentMethod> paymentMethods,
}) {
  return showModalBottomSheet<PaymentViewModel>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _AddPaymentBottomSheetContent(
        currency: currency,
        grandTotal: grandTotal,
        existingPayments: existingPayments,
        paymentMethods: paymentMethods,
      );
    },
  );
}

class _AddPaymentBottomSheetContent extends StatefulWidget {
  final String currency;
  final double grandTotal;
  final List<PaymentViewModel> existingPayments;
  final List<PaymentMethod> paymentMethods;

  const _AddPaymentBottomSheetContent({
    required this.currency,
    required this.grandTotal,
    required this.existingPayments,
    required this.paymentMethods,
  });

  @override
  State<_AddPaymentBottomSheetContent> createState() =>
      _AddPaymentBottomSheetContentState();
}

class _AddPaymentBottomSheetContentState
    extends State<_AddPaymentBottomSheetContent> {
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
      if (_selectedMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un moyen de paiement')),
        );
        return;
      }
      final amount = double.tryParse(_amountController.text);
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Montant invalide')),
        );
        return;
      }
      final payment = PaymentViewModel(
        amount: amount,
        method: _selectedMethod!.name,
      );
      Navigator.pop(context, payment);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'cash':
        return Icons.attach_money;
      case 'momo':
        return Icons.phone_android;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _money(double v) => NumberFormat.currency(
        locale: 'fr_FR',
        symbol: widget.currency,
        decimalDigits: 0,
      ).format(v);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final remaining = widget.grandTotal - _totalPaidSoFar;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ajouter un paiement',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Total de la commande : ${_money(widget.grandTotal)}'),
                Text('Déjà payé : ${_money(_totalPaidSoFar)}'),
                Text(
                  'Solde restant : ${_money(remaining)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
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
                    if (parsed > remaining) {
                      return 'Montant dépasse le solde restant';
                    }
                    final balance = _selectedMethod?.balance ?? 0;
                    if (_selectedMethod != null && parsed > balance) {
                      return 'Solde insuffisant sur ${_selectedMethod!.name}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _amountController.text = remaining.toStringAsFixed(0);
                      _formKey.currentState?.validate();
                    },
                    child: const Text('Payer la totalité'),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final method in widget.paymentMethods)
                      ChoiceChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(method.name),
                            Text(
                              _money(method.balance),
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        avatar: Icon(_iconForType(method.type)),
                        selected: _selectedMethod?.id == method.id,
                        onSelected: (_) =>
                            setState(() => _selectedMethod = method),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _onAdd,
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
