// lib/features/purchases/presentation/widgets/create_purchase/supplier_info_form.dart

import 'package:flutter/material.dart';

import 'form_widgets.dart';
import '../../../presentation/screens/create_purchase_screen.dart';

class SupplierInfoForm extends StatelessWidget {
  final String? supplier; // Changé de TextEditingController à String?
  final VoidCallback onSupplierTap; // Nouvelle callback pour le clic
  final String? warehouse;
  final VoidCallback onWarehouseTap;
  final String orderDate;
  final VoidCallback onOrderDateTap;
  final ReceptionStatusChoice receptionStatus;
  final ValueChanged<ReceptionStatusChoice> onReceptionStatusChanged;

  const SupplierInfoForm({
    super.key,
    required this.supplier,
    required this.onSupplierTap,
    required this.warehouse,
    required this.onWarehouseTap,
    required this.orderDate,
    required this.onOrderDateTap,
    required this.receptionStatus,
    required this.onReceptionStatusChanged,
  });

  static const _vGap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ Fournisseur (maintenant un PickerField)
        PickerField(
          key: const Key('supplier-field'),
          label: 'Fournisseur *',
          value: supplier ?? 'Sélectionner...',
          onTap: onSupplierTap,
          prefixIcon: Icons.store_mall_directory_outlined,
        ),
        const SizedBox(height: _vGap),

        // Champ Entrepôt
        PickerField(
          key: const Key('warehouse-field'),
          label: 'Entrepôt de destination *',
          value: warehouse ?? 'Sélectionner...',
          onTap: onWarehouseTap,
          prefixIcon: Icons.home_work_outlined,
        ),
        const SizedBox(height: _vGap),
        
        // Champ Date de commande
        PickerField(
          key: const Key('order-date-field'),
          label: 'Date de commande *',
          value: orderDate,
          onTap: onOrderDateTap,
          prefixIcon: Icons.event_outlined,
          trailing: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        const SizedBox(height: _vGap + 4),

        // Sélecteur de statut de réception
        StatusToggleButtons(
          selected: receptionStatus,
          onChanged: onReceptionStatusChanged,
        ),
      ],
    );
  }
}

class StatusToggleButtons extends StatelessWidget {
  final ReceptionStatusChoice selected;
  final ValueChanged<ReceptionStatusChoice> onChanged;

  const StatusToggleButtons({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Statut de la Réception',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
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
          selected: {selected},
          onSelectionChanged: (selection) {
            onChanged(selection.first);
          },
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: theme.textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}