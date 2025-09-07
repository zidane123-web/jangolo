// lib/features/purchases/presentation/widgets/create_purchase/payment_step.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/payment_view_model.dart';

class PaymentStep extends StatelessWidget {
  // --- Données pour le calcul des totaux ---
  final double grandTotal;
  final String currency;

  // --- Callbacks et valeurs pour les paiements ---
  final List<PaymentViewModel> payments;
  final VoidCallback onAddPayment;
  final ValueChanged<int> onRemovePayment;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const PaymentStep({
    super.key,
    required this.grandTotal,
    required this.currency,
    required this.payments,
    required this.onAddPayment,
    required this.onRemovePayment,
    required this.onBack,
    required this.onNext,
  });

  // Calcule le total payé à partir de la liste
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  // Calcule le solde restant
  double get balanceDue => grandTotal - totalPaid;

  String _money(num v) {
    final nf = NumberFormat("#,##0.##", "fr_FR");
    return "${nf.format(v)} $currency";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Section Paiements ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paiements', style: theme.textTheme.titleLarge),
                    FilledButton.tonalIcon(
                      onPressed: onAddPayment,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Affiche la liste des paiements ou un message si vide
                payments.isEmpty
                    ? const _EmptyPaymentState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return _PaymentTile(
                            payment: payment,
                            currency: currency,
                            onDelete: () => onRemovePayment(index),
                          );
                        },
                      ),

                const SizedBox(height: 16),
                _buildTotals(theme),
              ],
            ),
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

  // Widget pour afficher les totaux
  Widget _buildTotals(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _TotalRow(label: 'Total de la commande', value: _money(grandTotal)),
            const SizedBox(height: 8),
            _TotalRow(label: 'Total Payé', value: _money(totalPaid)),
            const Divider(height: 20),
            _TotalRow(
              label: balanceDue >= 0 ? 'Solde Restant' : 'Crédit',
              value: _money(balanceDue.abs()),
              isBold: true,
              color: balanceDue > 0 ? theme.colorScheme.error : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Petits widgets internes pour l'UI ----

class _EmptyPaymentState extends StatelessWidget {
  const _EmptyPaymentState();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          Icon(Icons.payment_outlined,
              size: 32, color: theme.colorScheme.secondary),
          const SizedBox(height: 8),
          Text(
            'Aucun paiement enregistré',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez sur "Ajouter" pour commencer.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentViewModel payment;
  final String currency;
  final VoidCallback onDelete;

  const _PaymentTile({
    required this.payment,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nf = NumberFormat("#,##0.##", "fr_FR");
    final formattedAmount = "${nf.format(payment.amount)} $currency";

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: const Icon(Icons.receipt_long_outlined),
        ),
        title: Text(formattedAmount,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Via: ${payment.method}'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 16 : 14,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}