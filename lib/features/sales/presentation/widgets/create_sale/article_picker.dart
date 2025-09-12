// lib/features/sales/presentation/widgets/create_sale/article_picker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../inventory/domain/entities/article_entity.dart';


Future<ArticleEntity?> showArticlePicker({
  required BuildContext context,
  required List<ArticleEntity> articles,
}) {
  return showModalBottomSheet<ArticleEntity>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    showDragHandle: true,
    builder: (context) {
      return _ArticlePickerSheet(articles: articles);
    },
  );
}

class _ArticlePickerSheet extends StatefulWidget {
  final List<ArticleEntity> articles;

  const _ArticlePickerSheet({required this.articles});

  @override
  State<_ArticlePickerSheet> createState() => _ArticlePickerSheetState();
}

class _ArticlePickerSheetState extends State<_ArticlePickerSheet> {
  late final TextEditingController _searchController;
  late List<ArticleEntity> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.articles;
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredItems = widget.articles
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sélectionner un article', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final article = _filteredItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(153)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.inventory_2_outlined, size: 20),
                    ),
                    title: Text(article.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Stock: ${article.totalQuantity}'),
                    trailing: Text(
                      _money(article.sellPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => Navigator.pop(context, article),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}