import 'package:flutter/material.dart';

import '../../screens/purchase_line_edit_screen.dart';

Future<LineItem?> editLineItem(BuildContext context, String currency,
    {LineItem? current}) {
  return Navigator.of(context).push<LineItem>(
    MaterialPageRoute(
      builder: (_) =>
          PurchaseLineEditScreen(initial: current, currency: currency),
    ),
  );
}

Future<bool> confirmRemoveLineItem(BuildContext context) async {
  final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer cet article ?'),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ) ??
      false;
  return shouldDelete;
}