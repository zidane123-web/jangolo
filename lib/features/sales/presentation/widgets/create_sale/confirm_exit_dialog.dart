// lib/features/sales/presentation/widgets/create_sale/confirm_exit_dialog.dart

import 'package:flutter/material.dart';

/// Affiche une boîte de dialogue pour confirmer que l'utilisateur veut
/// quitter l'écran et perdre les données saisies.
Future<bool> confirmSaleExit(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abandonner la vente ?'),
          content: const Text('Toutes les données saisies pour cette vente seront perdues.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Rester'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Abandonner'),
            ),
          ],
        ),
      ) ??
      false;
}