import 'package:flutter/material.dart';

import '../../screens/purchase_line_edit_screen.dart' show LineItem;
import 'purchase_summary_card.dart';

class SummaryStep extends StatelessWidget {
  final List<LineItem> items;
  final double shippingFees; // ✅ NOUVEAU: On reçoit les frais de transport
  final String currency;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback onValidate;

  const SummaryStep({
    super.key,
    required this.items,
    required this.shippingFees, // ✅ NOUVEAU
    required this.currency,
    required this.isSaving,
    required this.onBack,
    required this.onSaveDraft,
    required this.onValidate,
  });

  // ✅ Le calcul du total inclut maintenant les frais de transport
  double get grandTotal =>
      items.fold<double>(0.0, (total, item) => total + item.lineTotal.toDouble()) + shippingFees;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          PurchaseSummaryCard(
            grandTotal: grandTotal,
            currency: currency,
          ),
          const SizedBox(height: 32),
          if (isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: onBack, child: const Text('Retour')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onValidate,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Valider la Commande'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isSaving ? null : onSaveDraft,
              child: const Text('Enregistrer comme brouillon'),
            ),
          ),
        ],
      ),
    );
  }
}