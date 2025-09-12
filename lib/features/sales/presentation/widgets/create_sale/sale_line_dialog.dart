// lib/features/sales/presentation/widgets/create_sale/sale_line_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/sale_line_entity.dart';
import '../../../../inventory/domain/entities/article_entity.dart';

Future<SaleLineEntity?> showSaleLineDialog({
  required BuildContext context,
  required ArticleEntity article,
  SaleLineEntity? existingLine,
}) {
  return showDialog<SaleLineEntity>(
    context: context,
    builder: (context) {
      return _SaleLineDialogContent(
        article: article,
        existingLine: existingLine,
      );
    },
  );
}

class _SaleLineDialogContent extends StatefulWidget {
  final ArticleEntity article;
  final SaleLineEntity? existingLine;

  const _SaleLineDialogContent({
    required this.article,
    this.existingLine,
  });

  @override
  State<_SaleLineDialogContent> createState() => _SaleLineDialogContentState();
}

class _SaleLineDialogContentState extends State<_SaleLineDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
        text: widget.existingLine?.quantity.toStringAsFixed(0) ?? '1');
    _priceController = TextEditingController(
        text: (widget.existingLine?.unitPrice ?? widget.article.sellPrice)
            .toStringAsFixed(0));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    final newLine = SaleLineEntity(
      id: widget.existingLine?.id ??
          '${widget.article.id}-${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.article.id,
      name: widget.article.name,
      quantity: quantity,
      unitPrice: price,
      // Serialized info
      isSerialized: widget.article.hasSerializedUnits,
      scannedCodes: widget.existingLine?.scannedCodes ?? [],
    );

    Navigator.of(context).pop(newLine);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.article.name),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText:
                    widget.article.hasSerializedUnits ? 'Quantité à vendre' : 'Quantité',
                suffixText: 'en stock: ${widget.article.totalQuantity}',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                final qty = int.tryParse(value) ?? 0;
                if (qty <= 0) return 'Doit être > 0';
                if (qty > widget.article.totalQuantity) {
                  return 'Stock insuffisant';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix de vente unitaire',
                suffixText: 'F CFA',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                if ((double.tryParse(value) ?? -1) < 0) return 'Prix invalide';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}