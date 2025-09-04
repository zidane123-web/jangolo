// lib/features/purchases/presentation/widgets/create_purchase/line_items_section.dart

import 'package:flutter/material.dart';

import '../../screens/purchase_line_edit_screen.dart'; // Pour le type LineItem
import 'form_widgets.dart'; // ➜ L'IMPORT MANQUANT EST AJOUTÉ ICI

class LineItemsSection extends StatelessWidget {
  final List<LineItem> items;
  final String currency;
  final VoidCallback onAddItem;
  final void Function(LineItem, int) onEditItem;
  final ValueChanged<int> onRemoveItem;

  const LineItemsSection({
    super.key,
    required this.items,
    required this.currency,
    required this.onAddItem,
    required this.onEditItem,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    // On utilise maintenant un Column simple, car le titre n'est plus nécessaire.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Articles commandés',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            FilledButton.tonalIcon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        items.isEmpty
            ? const EmptyState(
                icon: Icons.playlist_add_outlined,
                text: 'Aucun article pour le moment.\nCliquez sur "Ajouter" pour commencer.',
              )
            : ListView.separated(
                shrinkWrap: true,
                primary: false,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return LineTile(
                    item: item,
                    currency: currency,
                    onEdit: () => onEditItem(item, i),
                    onDelete: () => onRemoveItem(i),
                  );
                },
              ),
      ],
    );
  }
}