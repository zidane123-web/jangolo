import 'package:flutter/material.dart';

import '../../../../settings/domain/entities/management_entities.dart';
import '../../../../settings/presentation/screens/add_edit_warehouse_screen.dart';
import '../../../../settings/presentation/screens/add_supplier_screen.dart';
import 'styled_picker.dart';

/// Ouvre le sélecteur d'entrepôt.
/// Renvoie l'entrepôt sélectionné ou null.
Future<Warehouse?> pickWarehouse({
  required BuildContext context,
  required List<Warehouse> warehouses,
}) async {
  final selectedName = await showStyledPicker(
    context: context,
    title: 'Sélectionner un entrepôt',
    items: warehouses.map((e) => e.name).toList(),
    icon: Icons.home_work_outlined,
    actionButton: TextButton(
      onPressed: () {
        // Ferme le sélecteur actuel et indique qu'on veut créer.
        Navigator.of(context).pop('__CREATE__');
      },
      child: const Text('Créer'),
    ),
  );

  if (selectedName == null) return null;

  // Si l'utilisateur a cliqué sur "Créer", on renvoie une valeur spéciale.
  if (selectedName == '__CREATE__') {
    return await Navigator.of(context)
        .push<Warehouse>(MaterialPageRoute(builder: (_) => const AddEditWarehouseScreen()));
  }

  return warehouses.firstWhere((w) => w.name == selectedName);
}

/// Ouvre le sélecteur de fournisseur.
/// Renvoie le fournisseur sélectionné ou null.
Future<Supplier?> pickSupplier({
  required BuildContext context,
  required List<Supplier> suppliers,
}) async {
  final selectedName = await showStyledPicker(
    context: context,
    title: 'Sélectionner un fournisseur',
    items: suppliers.map((e) => e.name).toList(),
    icon: Icons.store_mall_directory_outlined,
    actionButton: TextButton(
      onPressed: () {
        // Ferme le sélecteur actuel et indique qu'on veut créer.
        Navigator.of(context).pop('__CREATE__');
      },
      child: const Text('Créer'),
    ),
  );

  if (selectedName == null) return null;

  // Si l'utilisateur a cliqué sur "Créer", on ouvre l'écran de création.
  if (selectedName == '__CREATE__') {
    return await Navigator.of(context)
        .push<Supplier>(MaterialPageRoute(builder: (_) => const AddSupplierScreen()));
  }

  return suppliers.firstWhere((s) => s.name == selectedName);
}