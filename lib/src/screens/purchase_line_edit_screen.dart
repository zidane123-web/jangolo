import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Types partagés (publics) pour être utilisés par CreatePurchaseScreen.
enum DiscountType { none, percent, fixed }

class LineItem {
  final String name;
  final String? sku;
  final double qty;
  final double unitPrice;
  final DiscountType discountType;
  final double discountValue; // % si percent, montant si fixed
  final double vatRate; // 0.18 => 18%

  LineItem({
    required this.name,
    this.sku,
    required this.qty,
    required this.unitPrice,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    this.vatRate = 0.18,
  })  : assert(qty >= 0),
        assert(unitPrice >= 0),
        assert(discountValue >= 0);

  num get gross => qty * unitPrice;

  num get lineDiscount {
    switch (discountType) {
      case DiscountType.none:
        return 0;
      case DiscountType.percent:
        return gross * (discountValue / 100.0);
      case DiscountType.fixed:
        return discountValue.clamp(0, gross);
    }
  }

  num get lineSubtotal => (gross - lineDiscount).clamp(0, double.infinity);

  num get lineTax => lineSubtotal * vatRate;

  num get lineTotal => lineSubtotal + lineTax;

  LineItem copyWith({
    String? name,
    String? sku,
    double? qty,
    double? unitPrice,
    DiscountType? discountType,
    double? discountValue,
    double? vatRate,
  }) {
    return LineItem(
      name: name ?? this.name,
      sku: sku ?? this.sku,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      vatRate: vatRate ?? this.vatRate,
    );
  }
}

/// Page d’édition/ajout d’une ligne d’article.
/// Retourne un `LineItem` via `Navigator.pop(context, lineItem)`.
class PurchaseLineEditScreen extends StatefulWidget {
  final LineItem? initial;
  final String currency;

  const PurchaseLineEditScreen({
    super.key,
    this.initial,
    required this.currency,
  });

  @override
  State<PurchaseLineEditScreen> createState() => _PurchaseLineEditScreenState();
}

class _PurchaseLineEditScreenState extends State<PurchaseLineEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _sku =
      TextEditingController(text: widget.initial?.sku ?? '');
  late final TextEditingController _qty =
      TextEditingController(text: _fmtNum(widget.initial?.qty ?? 1));
  late final TextEditingController _unitPrice =
      TextEditingController(text: _fmtNum(widget.initial?.unitPrice ?? 0));
  late DiscountType _discountType =
      widget.initial?.discountType ?? DiscountType.none;
  late final TextEditingController _discountValue = TextEditingController(
      text: _fmtNum(widget.initial?.discountValue ?? 0));
  late double _vatRate = widget.initial?.vatRate ?? 0.18;

  String _fmtNum(num v) => NumberFormat("#,##0.##", "fr_FR").format(v);

  num _parseNum(String v) {
    final clean = v.replaceAll(' ', '').replaceAll(',', '.');
    return num.tryParse(clean) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null
            ? 'Ajouter une ligne'
            : 'Modifier la ligne'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _SectionCard(
                title: 'Article',
                child: Column(
                  children: [
                    _LabeledTextField(
                      controller: _name,
                      label: 'Désignation *',
                      hint: 'Ex. iPhone 15 128 Go Noir',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      prefixIcon: Icons.inventory_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            controller: _sku,
                            label: 'SKU / Référence',
                            hint: 'Ex. IP15-128-BLK',
                            prefixIcon: Icons.qr_code_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _qty,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d,\.\s]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Quantité *',
                              prefixIcon: const Icon(
                                  Icons.confirmation_number_outlined),
                              filled: true,
                              fillColor: cs.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => (_parseNum(v ?? '') <= 0)
                                ? 'Quantité > 0'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _unitPrice,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d,\.\s]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Prix unitaire *',
                              prefixIcon:
                                  const Icon(Icons.payments_outlined),
                              suffixText: widget.currency,
                              filled: true,
                              fillColor: cs.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => (_parseNum(v ?? '') < 0)
                                ? 'Prix ≥ 0'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DropdownField<DiscountType>(
                            label: 'Type remise',
                            value: _discountType,
                            items: const [
                              DiscountType.none,
                              DiscountType.percent,
                              DiscountType.fixed
                            ],
                            itemBuilder: (t) {
                              switch (t) {
                                case DiscountType.none:
                                  return 'Aucune';
                                case DiscountType.percent:
                                  return 'Pourcentage';
                                case DiscountType.fixed:
                                  return 'Montant';
                              }
                            },
                            onChanged: (v) => setState(
                                () => _discountType = v ?? DiscountType.none),
                            prefixIcon: Icons.local_offer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountValue,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d,\.\s]')),
                            ],
                            decoration: InputDecoration(
                              labelText: _discountType == DiscountType.percent
                                  ? 'Valeur remise (%)'
                                  : 'Valeur remise',
                              prefixIcon:
                                  const Icon(Icons.discount_outlined),
                              suffixText:
                                  _discountType == DiscountType.percent
                                      ? '%'
                                      : widget.currency,
                              filled: true,
                              fillColor: cs.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DropdownField<double>(
                            label: 'TVA ligne',
                            value: _vatRate,
                            items: [0.0, 0.05, 0.10, 0.18, 0.20],
                            itemBuilder: (v) =>
                                '${(v * 100).toStringAsFixed(0)} %',
                            onChanged: (v) =>
                                setState(() => _vatRate = v ?? 0.0),
                            prefixIcon: Icons.percent_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final item = LineItem(
                          name: _name.text.trim(),
                          sku: _sku.text.trim().isEmpty
                              ? null
                              : _sku.text.trim(),
                          qty: _parseNum(_qty.text).toDouble(),
                          unitPrice:
                              _parseNum(_unitPrice.text).toDouble(),
                          discountType: _discountType,
                          discountValue:
                              _parseNum(_discountValue.text).toDouble(),
                          vatRate: _vatRate,
                        );
                        Navigator.pop(context, item);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Enregistrer la ligne'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ Petits widgets réutilisés localement ---------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const _LabeledTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.textInputAction,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T)? itemBuilder;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.itemBuilder,
    this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(itemBuilder?.call(e) ?? e.toString()),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
