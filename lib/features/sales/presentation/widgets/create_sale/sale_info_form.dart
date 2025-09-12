// lib/features/sales/presentation/widgets/create_sale/sale_info_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../purchases/presentation/widgets/create_purchase/form_widgets.dart';

class SaleInfoForm extends StatelessWidget {
  final String? client;
  final VoidCallback onClientTap;
  final String? warehouse;
  final VoidCallback onWarehouseTap;
  final DateTime saleDate;
  final VoidCallback onSaleDateTap;

  const SaleInfoForm({
    super.key,
    required this.client,
    required this.onClientTap,
    required this.warehouse,
    required this.onWarehouseTap,
    required this.saleDate,
    required this.onSaleDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PickerFormField(
          key: const Key('client-field'),
          label: 'Client *',
          value: client,
          onTap: onClientTap,
          prefixIcon: Icons.person_outline,
          validator: (v) => v == null ? 'Veuillez sélectionner un client' : null,
        ),
        const SizedBox(height: 16),
        PickerFormField(
          key: const Key('warehouse-field'),
          label: "Vendu depuis l'entrepôt *",
          value: warehouse,
          onTap: onWarehouseTap,
          prefixIcon: Icons.home_work_outlined,
          validator: (v) => v == null ? 'Veuillez sélectionner un entrepôt' : null,
        ),
        const SizedBox(height: 16),
        PickerField(
          key: const Key('sale-date-field'),
          label: 'Date de la vente *',
          value: DateFormat('dd/MM/yyyy', 'fr_FR').format(saleDate),
          onTap: onSaleDateTap,
          prefixIcon: Icons.event_outlined,
          trailing: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
      ],
    );
  }
}
