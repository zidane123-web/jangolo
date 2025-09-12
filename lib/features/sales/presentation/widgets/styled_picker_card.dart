// lib/features/sales/presentation/widgets/styled_picker_card.dart

import 'package:flutter/material.dart';

class StyledPickerCard extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  const StyledPickerCard({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Couleurs inspirées de sales_list_screen.dart
    const textColor = Color(0xFF111827);
    const mutedTextColor = Color(0xFF6B7280);
    const borderColor = Color(0xFFE5E7EB);
    const backgroundColor = Color(0xFFF3F4F6); // Fond des chips de filtre

    final hasValue = value != null && value!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: mutedTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasValue ? value! : placeholder,
                  style: TextStyle(
                    color: hasValue ? textColor : mutedTextColor,
                    fontSize: 16,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                Icon(icon, color: mutedTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}