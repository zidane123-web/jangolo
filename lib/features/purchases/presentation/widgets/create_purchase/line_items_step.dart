import 'package:flutter/material.dart';

import '../../screens/purchase_line_edit_screen.dart' show LineItem;
import 'line_items_section.dart';
import 'line_item_actions.dart';

class LineItemsStep extends StatelessWidget {
  final List<LineItem> items;
  final String currency;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final void Function(void Function()) refresh;

  const LineItemsStep({
    super.key,
    required this.items,
    required this.currency,
    required this.onBack,
    required this.onNext,
    required this.refresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: LineItemsSection(
              items: items,
              currency: currency,
              onAddItem: () async {
                final result = await editLineItem(context, currency);
                if (result != null) refresh(() => items.add(result));
              },
              onEditItem: (item, index) async {
                final result = await editLineItem(context, currency, current: item);
                if (result != null) refresh(() => items[index] = result);
              },
              onRemoveItem: (index) async {
                final shouldDelete = await confirmRemoveLineItem(context);
                if (shouldDelete) refresh(() => items.removeAt(index));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                OutlinedButton(onPressed: onBack, child: const Text('Retour')),
                const Spacer(),
                FilledButton(onPressed: onNext, child: const Text('Suivant')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
