import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ➜ L'import vers nos entités reste inchangé
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

  // Fonctions utilitaires pour la gestion des nombres
  String _fmtNum(num v) => NumberFormat("#,##0.##", "fr_FR").format(v);
  num _parseNum(String v) {
    final clean = v.replaceAll(' ', '').replaceAll(',', '.');
    return num.tryParse(clean) ?? 0;
  }

  // ✅ --- NOUVEAU HELPER POUR LE STYLE DES CHAMPS ---
  InputDecoration _m3InputDecoration(BuildContext context,
      {required String label, String? suffixText}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ --- FOND BLANC ET APPBAR ÉPURÉE ---
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            Text(widget.initial == null ? 'Ajouter un article' : 'Modifier l\'article'),
        backgroundColor: Colors.white,
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // ✅ --- LISTVIEW POUR QUE TOUT SOIT SCROLLABLE ---
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              // --- SECTION ARTICLE ---
              Text('Détails de l\'article', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: _m3InputDecoration(context, label: 'Désignation *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sku,
                      decoration: _m3InputDecoration(context, label: 'SKU / Référence'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _qty,
                      decoration: _m3InputDecoration(context, label: 'Quantité *'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          (_parseNum(v ?? '') <= 0) ? 'Doit être > 0' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- SECTION PRIX & REMISE ---
              Text('Prix et Remise', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitPrice,
                      decoration: _m3InputDecoration(
                        context,
                        label: 'Prix unitaire *',
                        suffixText: widget.currency,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          (_parseNum(v ?? '') < 0) ? 'Doit être ≥ 0' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<DiscountType>(
                      value: _discountType,
                      decoration: _m3InputDecoration(context, label: 'Type remise'),
                      items: const [
                        DropdownMenuItem(
                            value: DiscountType.none, child: Text('Aucune')),
                        DropdownMenuItem(
                            value: DiscountType.percent,
                            child: Text('Pourcentage (%)')),
                        DropdownMenuItem(
                            value: DiscountType.fixed, child: Text('Montant fixe')),
                      ],
                      onChanged: (v) =>
                          setState(() => _discountType = v ?? DiscountType.none),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_discountType != DiscountType.none)
                TextFormField(
                  controller: _discountValue,
                  decoration: _m3InputDecoration(
                    context,
                    label: 'Valeur de la remise',
                    suffixText:
                        _discountType == DiscountType.percent ? '%' : widget.currency,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              
              const SizedBox(height: 32),

              // ✅ --- BOUTONS D'ACTION À LA FIN DU SCROLL ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final item = LineItem(
                          name: _name.text.trim(),
                          sku: _sku.text.trim().isEmpty
                              ? null
                              : _sku.text.trim(),
                          qty: _parseNum(_qty.text).toDouble(),
                          unitPrice: _parseNum(_unitPrice.text).toDouble(),
                          discountType: _discountType,
                          discountValue:
                              _parseNum(_discountValue.text).toDouble(),
                          vatRate: _vatRate,
                        );
                        Navigator.pop(context, item);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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