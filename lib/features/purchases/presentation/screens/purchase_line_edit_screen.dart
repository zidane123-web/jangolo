import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ➜ NOUVEL IMPORT: On importe nos entités pour avoir la VRAIE définition de DiscountType
import '../../domain/entities/purchase_line_entity.dart';


// utilisé uniquement pour faire passer des informations à cet écran.
class LineItem {
  final String name;
  final String? sku;
  final double qty;
  final double unitPrice;
  final DiscountType discountType;
  final double discountValue;
  final double vatRate;

  LineItem({
    required this.name,
    this.sku,
    required this.qty,
    required this.unitPrice,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    this.vatRate = 0.18,
  });

  num get gross => qty * unitPrice;
  num get lineDiscount {
    switch (discountType) {
      case DiscountType.none: return 0;
      case DiscountType.percent: return gross * (discountValue / 100.0);
      case DiscountType.fixed: return discountValue.clamp(0, gross);
    }
  }
  num get lineSubtotal => (gross - lineDiscount).clamp(0, double.infinity);
  num get lineTax => lineSubtotal * vatRate;
  num get lineTotal => lineSubtotal + lineTax;
}

/// Page d’édition/ajout d’une ligne d’article.
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

  late final TextEditingController _name = TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _sku = TextEditingController(text: widget.initial?.sku ?? '');
  late final TextEditingController _qty = TextEditingController(text: _fmtNum(widget.initial?.qty ?? 1));
  late final TextEditingController _unitPrice = TextEditingController(text: _fmtNum(widget.initial?.unitPrice ?? 0));
  late DiscountType _discountType = widget.initial?.discountType ?? DiscountType.none;
  late final TextEditingController _discountValue = TextEditingController(text: _fmtNum(widget.initial?.discountValue ?? 0));
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
        title: Text(widget.initial == null ? 'Ajouter une ligne' : 'Modifier la ligne'),
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
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Désignation *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU / Référence'))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _qty,
                            decoration: const InputDecoration(labelText: 'Quantité *'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => (_parseNum(v ?? '') <= 0) ? 'Quantité > 0' : null,
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
                            decoration: InputDecoration(labelText: 'Prix unitaire *', suffixText: widget.currency),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => (_parseNum(v ?? '') < 0) ? 'Prix ≥ 0' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<DiscountType>(
                            value: _discountType,
                            decoration: const InputDecoration(labelText: 'Type remise'),
                            items: const [
                              DropdownMenuItem(value: DiscountType.none, child: Text('Aucune')),
                              DropdownMenuItem(value: DiscountType.percent, child: Text('Pourcentage')),
                              DropdownMenuItem(value: DiscountType.fixed, child: Text('Montant')),
                            ],
                            onChanged: (v) => setState(() => _discountType = v ?? DiscountType.none),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discountValue,
                      decoration: InputDecoration(
                        labelText: 'Valeur remise',
                        suffixText: _discountType == DiscountType.percent ? '%' : widget.currency,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final item = LineItem(
                          name: _name.text.trim(),
                          sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
                          qty: _parseNum(_qty.text).toDouble(),
                          unitPrice: _parseNum(_unitPrice.text).toDouble(),
                          discountType: _discountType,
                          discountValue: _parseNum(_discountValue.text).toDouble(),
                          vatRate: _vatRate,
                        );
                        Navigator.pop(context, item);
                      },
                      child: const Text('Enregistrer la ligne'),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}