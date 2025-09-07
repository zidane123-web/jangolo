import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../create_purchase/supplier_info_form.dart';

class SupplierAndWarehouseStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? supplier;
  final VoidCallback onSupplierTap;
  final String? warehouse;
  final VoidCallback onWarehouseTap;
  final DateTime orderDate;
  final VoidCallback onOrderDateTap;
  final VoidCallback onNext;

  const SupplierAndWarehouseStep({
    super.key,
    required this.formKey,
    required this.supplier,
    required this.onSupplierTap,
    required this.warehouse,
    required this.onWarehouseTap,
    required this.orderDate,
    required this.onOrderDateTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          Form(
            key: formKey,
            child: SupplierInfoForm(
              supplier: supplier,
              onSupplierTap: onSupplierTap,
              warehouse: warehouse,
              onWarehouseTap: onWarehouseTap,
              orderDate: DateFormat('dd/MM/yyyy', 'fr_FR').format(orderDate),
              onOrderDateTap: onOrderDateTap,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}
