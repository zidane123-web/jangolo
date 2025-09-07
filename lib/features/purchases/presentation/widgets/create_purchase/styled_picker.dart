import 'package:flutter/material.dart';

/// Displays a modal bottom sheet with search and returns the selected item.
Future<String?> showStyledPicker({
  required BuildContext context,
  required String title,
  required List<String> items,
  required IconData icon,
  Widget? actionButton,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    showDragHandle: true,
    builder: (context) {
      return _StyledPickerSheet(
        title: title,
        items: items,
        icon: icon,
        actionButton: actionButton,
      );
    },
  );
}

class _StyledPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Widget? actionButton;

  const _StyledPickerSheet({
    required this.title,
    required this.items,
    required this.icon,
    this.actionButton,
  });

  @override
  State<_StyledPickerSheet> createState() => _StyledPickerSheetState();
}

class _StyledPickerSheetState extends State<_StyledPickerSheet> {
  late final TextEditingController _searchController;
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.title, style: theme.textTheme.titleLarge),
              ),
              if (widget.actionButton != null) widget.actionButton!,
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
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
                final item = _filteredItems[index];
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
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withAlpha(25),
                      child: Icon(widget.icon, size: 20),
                    ),
                    title: Text(item,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(context, item),
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
