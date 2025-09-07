import 'package:flutter/material.dart';

Future<bool> confirmExit(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abandonner l\'achat ?'),
          content: const Text('Toutes les données saisies seront perdues.'),
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
