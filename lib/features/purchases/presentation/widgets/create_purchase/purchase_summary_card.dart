// lib/features/purchases/presentation/widgets/create_purchase/purchase_summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseSummaryCard extends StatelessWidget {
  final num grandTotal;
  final String currency;

  const PurchaseSummaryCard({
    super.key,
    required this.grandTotal,
    required this.currency,
  });

  String _money(num v) {
    final nf = NumberFormat("#,##0.00", "fr_FR");
    return "${nf.format(v)} $currency";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Total Général',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _money(grandTotal),
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          "Veuillez vérifier toutes les informations avant de valider la commande.",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}