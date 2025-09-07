// lib/features/purchases/presentation/widgets/create_purchase/shipping_and_reception_step.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/reception_status_choice.dart';

class ShippingAndReceptionStep extends StatelessWidget {
  // ✅ MODIFICATION: Le type est maintenant nullable
  final ReceptionStatusChoice? receptionStatus;
  final ValueChanged<ReceptionStatusChoice?> onReceptionStatusChanged;
  final TextEditingController shippingFeesController;
  final String currency;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ShippingAndReceptionStep({
    super.key,
    required this.receptionStatus,
    required this.onReceptionStatusChanged,
    required this.shippingFeesController,
    required this.currency,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Section Réception ---
                  Text('Statut de la Réception *',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),

                  // ✅ REMPLACEMENT: Le SegmentedButton est remplacé par deux SwitchListTile
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: SwitchListTile(
                      title: const Text('Marchandises à Recevoir'),
                      value: receptionStatus == ReceptionStatusChoice.toReceive,
                      onChanged: (bool value) {
                        if (value) {
                          onReceptionStatusChanged(ReceptionStatusChoice.toReceive);
                        } else {
                          // Si l'utilisateur désactive cet interrupteur, rien n'est sélectionné
                          onReceptionStatusChanged(null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: SwitchListTile(
                      title: const Text('Marchandises Reçues'),
                      value:
                          receptionStatus == ReceptionStatusChoice.alreadyReceived,
                      onChanged: (bool value) {
                        if (value) {
                          onReceptionStatusChanged(
                              ReceptionStatusChoice.alreadyReceived);
                        } else {
                          // Si l'utilisateur désactive cet interrupteur, rien n'est sélectionné
                          onReceptionStatusChanged(null);
                        }
                      },
                    ),
                  ),

                  const Divider(height: 48),

                  // --- Section Frais de transport ---
                  Text('Frais Additionnels', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: shippingFeesController,
                    decoration: InputDecoration(
                      labelText: 'Frais de transport',
                      suffixText: currency,
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                OutlinedButton(onPressed: onBack, child: const Text('Retour')),
                const Spacer(),
                FilledButton(onPressed: onNext, child: const Text('Suivant')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}