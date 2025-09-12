// lib/features/sales/presentation/widgets/client_picker.dart

import 'package:flutter/material.dart';

import '../../../purchases/presentation/widgets/create_purchase/styled_picker.dart';
import '../../domain/entities/client_entity.dart';
import '../screens/add_client_screen.dart';

/// Ouvre le sélecteur de client.
/// Renvoie le client sélectionné ou un nouveau client créé.
Future<ClientEntity?> pickClient({
  required BuildContext context,
  required List<ClientEntity> clients,
}) async {
  final selectedName = await showStyledPicker(
    context: context,
    title: 'Sélectionner un client',
    items: clients.map((e) => e.name).toList(),
    icon: Icons.person_outline,
    actionButton: TextButton(
      onPressed: () {
        Navigator.of(context).pop('__CREATE__');
      },
      child: const Text('Créer'),
    ),
  );

  if (selectedName == null) return null;

  if (selectedName == '__CREATE__') {
    return await Navigator.of(context).push<ClientEntity>(
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
  }

  return clients.firstWhere((c) => c.name == selectedName);
}
