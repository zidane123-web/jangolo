// lib/features/purchases/presentation/widgets/create_purchase/supplier_info_form.dart

import 'package:flutter/material.dart';

import 'form_widgets.dart';

class SupplierInfoForm extends StatelessWidget {
  final String? supplier;
  final VoidCallback onSupplierTap;
  final String? warehouse;
  final VoidCallback onWarehouseTap;
  final String orderDate;
  final VoidCallback onOrderDateTap;

  // ✅ MODIFICATION: Les champs liés au statut de réception sont supprimés.
  const SupplierInfoForm({
    super.key,
    required this.supplier,
    required this.onSupplierTap,
    required this.warehouse,
    required this.onWarehouseTap,
    required this.orderDate,
    required this.onOrderDateTap,
  });

  static const _vGap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ Fournisseur (FormField pour validation)
        PickerFormField(
          key: const Key('supplier-field'),
          label: 'Fournisseur *',
          value: supplier,
          onTap: onSupplierTap,
          prefixIcon: Icons.store_mall_directory_outlined,
          validator: (v) => v == null ? 'Requis' : null,
        ),
        const SizedBox(height: _vGap),

        // Champ Entrepôt
        PickerFormField(
          key: const Key('warehouse-field'),
          label: 'Entrepôt de destination *',
          value: warehouse,
          onTap: onWarehouseTap,
          prefixIcon: Icons.home_work_outlined,
          validator: (v) => v == null ? 'Requis' : null,
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
        // ✅ MODIFICATION: Le sélecteur de statut de réception a été retiré d'ici.
      ],
    );
  }
}

// ✅ MODIFICATION: Le widget StatusToggleButtons n'est plus nécessaire dans ce fichier.
// Il sera recréé dans notre nouvelle étape.