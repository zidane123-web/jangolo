import 'package:flutter/material.dart';

import '../../../settings/domain/entities/management_entities.dart';
import '../../../settings/presentation/screens/add_edit_warehouse_screen.dart';
import '../../../settings/presentation/screens/add_supplier_screen.dart';
import '../../controllers/create_purchase_controller.dart';
import 'styled_picker.dart';

Future<Warehouse?> pickWarehouse({
  required BuildContext context,
  required List<Warehouse> warehouses,
  required CreatePurchaseController controller,
  required void Function(String message, {bool isError}) snack,
}) async {
  final selectedName = await showStyledPicker(
    context: context,
    title: 'Sélectionner un entrepôt',
    items: warehouses.map((e) => e.name).toList(),
    icon: Icons.home_work_outlined,
    actionButton: TextButton(
      onPressed: () async {
        Navigator.pop(context);
        final res = await Navigator.of(context)
            .push<Warehouse>(MaterialPageRoute(builder: (_) => const AddEditWarehouseScreen()));
        if (res != null) {
          try {
            final saved = await controller.addWarehouse(name: res.name, address: res.address);
            warehouses.add(saved);
          } catch (e) {
            snack("Erreur de sauvegarde de l'entrepôt: $e", isError: true);
          }
        }
      },
      child: const Text('Créer'),
    ),
  );
  if (selectedName == null) return null;
  return warehouses.firstWhere((w) => w.name == selectedName);
}

Future<Supplier?> pickSupplier({
  required BuildContext context,
  required List<Supplier> suppliers,
  required CreatePurchaseController controller,
  required void Function(String message, {bool isError}) snack,
}) async {
  final selectedName = await showStyledPicker(
    context: context,
    title: 'Sélectionner un fournisseur',
    items: suppliers.map((e) => e.name).toList(),
    icon: Icons.store_mall_directory_outlined,
    actionButton: TextButton(
      onPressed: () async {
        Navigator.pop(context);
        final res = await Navigator.of(context)
            .push<Supplier>(MaterialPageRoute(builder: (_) => const AddSupplierScreen()));
        if (res != null) {
          try {
            final saved = await controller.addSupplier(name: res.name, phone: res.phone);
            suppliers.add(saved);
          } catch (e) {
            snack("Erreur de sauvegarde du fournisseur: $e", isError: true);
          }
        }
      },
      child: const Text('Créer'),
    ),
  );
  if (selectedName == null) return null;
  return suppliers.firstWhere((s) => s.name == selectedName);
}
