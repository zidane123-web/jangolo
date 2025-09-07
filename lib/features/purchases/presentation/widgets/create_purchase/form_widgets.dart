// lib/features/purchases/presentation/widgets/create_purchase/form_widgets.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../screens/purchase_line_edit_screen.dart'; // Pour LineItem

// Helper pour un style d'input M3 sur fond blanc
InputDecoration _m3InputDecoration(BuildContext context,
    {required String label, String? hint, IconData? prefixIcon}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: cs.onSurfaceVariant),
    filled: true,
    fillColor: Colors.white, // Fond blanc pour les champs
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant), // Bordure subtile
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 2.0),
    ),
  );
}

class LabeledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: _m3InputDecoration(context,
          label: label, hint: hint, prefixIcon: prefixIcon),
    );
  }
}

// NOUVEAU WIDGET générique pour les sélecteurs (Date, Entrepôt, etc.)
class PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? prefixIcon;
  final Widget? trailing;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.prefixIcon,
    this.trailing = const Icon(Icons.arrow_drop_down),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _m3InputDecoration(context, label: label, prefixIcon: prefixIcon),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// Version FormField avec validation pour les PickerField
class PickerFormField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const PickerFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (state) {
        if (state.value != value) state.didChange(value);
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _m3InputDecoration(
                  context,
                  label: label,
                  prefixIcon: prefixIcon,
                ).copyWith(errorText: state.errorText),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                value ?? 'Sélectionner...',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LineTile extends StatelessWidget {
  final LineItem item;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LineTile({
    super.key,
    required this.item,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final nf = NumberFormat("#,##0.00", "fr_FR");
    String money(num v) => "${nf.format(v)} $currency";

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: cs.secondaryContainer,
        foregroundColor: cs.onSecondaryContainer,
        child: const Icon(Icons.inventory_2_outlined),
      ),
      title: Text(item.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('Total: ${money(item.lineTotal)}', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              tooltip: 'Modifier',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
              tooltip: 'Supprimer',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: cs.error)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
         border: Border.all(color: cs.outlineVariant.withAlpha(128)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: cs.primary, size: 32),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}