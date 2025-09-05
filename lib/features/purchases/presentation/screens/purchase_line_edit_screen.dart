// lib/features/purchases/presentation/screens/purchase_line_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/purchase_line_entity.dart';
import 'qr_scanner_screen.dart';

// ✅ --- MODIFICATION: Le modèle `LineItem` inclut maintenant la TVA ---
class LineItem {
  final String name;
  final String? sku;
  final List<List<String>> scannedCodeGroups;
  final double unitPrice;
  final DiscountType discountType;
  final double discountValue;
  final double vatRate; // CHAMP AJOUTÉ
  final int codesPerItem;

  LineItem({
    required this.name,
    this.sku,
    this.scannedCodeGroups = const [],
    required this.unitPrice,
    this.discountType = DiscountType.none,
    this.discountValue = 0.0,
    required this.vatRate, // RENDU OBLIGATOIRE
    this.codesPerItem = 1,
  });

  num get qty => scannedCodeGroups.length;
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
  late final TextEditingController _unitPrice = TextEditingController(text: _fmtNum(widget.initial?.unitPrice ?? 0));
  late DiscountType _discountType = widget.initial?.discountType ?? DiscountType.none;
  late final TextEditingController _discountValue = TextEditingController(text: _fmtNum(widget.initial?.discountValue ?? 0));
  
  // ✅ --- NOUVEAU: Controller pour le champ TVA ---
  late final TextEditingController _vatRate = TextEditingController(text: ((widget.initial?.vatRate ?? 0.18) * 100).toStringAsFixed(0));

  late final TextEditingController _codesPerItemCtrl = TextEditingController(text: widget.initial?.codesPerItem.toString() ?? '1');
  late List<List<String>> _scannedCodeGroups = widget.initial?.scannedCodeGroups ?? [];

  String _fmtNum(num v) => NumberFormat("#,##0.##", "fr_FR").format(v);
  num _parseNum(String v) {
    final clean = v.replaceAll(' ', '').replaceAll(',', '.');
    return num.tryParse(clean) ?? 0;
  }
  
  Future<void> _openScanner() async {
    if (!_formKey.currentState!.validate()) return;

    final codesPerItem = int.tryParse(_codesPerItemCtrl.text) ?? 1;
    
    final result = await Navigator.of(context).push<List<List<String>>>(
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          codesPerItem: codesPerItem,
          alreadyScannedGroups: _scannedCodeGroups,
        ),
      ),
    );
    if (result != null) {
      setState(() => _scannedCodeGroups = result);
    }
  }

  InputDecoration _m3InputDecoration(BuildContext context, {required String label, String? suffixText}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 2.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Ajouter un article' : 'Modifier l\'article'),
        backgroundColor: Colors.white,
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Text('Détails de l\'article', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: _m3InputDecoration(context, label: 'Désignation *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 24),
              
              Text('Quantité par Scan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codesPerItemCtrl,
                decoration: _m3InputDecoration(context, label: 'Nombre de codes par article *'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if ((int.tryParse(v) ?? 0) < 1) return 'Doit être > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              _ScanResultTile(
                count: _scannedCodeGroups.length,
                onTap: _openScanner,
              ),

              const SizedBox(height: 24),

              Text('Prix, Remise et TVA', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _unitPrice,
                      decoration: _m3InputDecoration(context, label: 'Prix unitaire *', suffixText: widget.currency),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (_parseNum(v ?? '') < 0) ? 'Doit être ≥ 0' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ --- NOUVEAU: Champ pour la TVA ---
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _vatRate,
                      decoration: _m3InputDecoration(context, label: 'TVA *', suffixText: '%'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final val = _parseNum(v);
                        if (val < 0) return '≥ 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DiscountType>(
                      value: _discountType,
                      decoration: _m3InputDecoration(context, label: 'Type remise'),
                      items: const [
                        DropdownMenuItem(value: DiscountType.none, child: Text('Aucune')),
                        DropdownMenuItem(value: DiscountType.percent, child: Text('Pourcentage (%)')),
                        DropdownMenuItem(value: DiscountType.fixed, child: Text('Montant fixe')),
                      ],
                      onChanged: (v) => setState(() => _discountType = v ?? DiscountType.none),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_discountType != DiscountType.none)
                    Expanded(
                      child: TextFormField(
                        controller: _discountValue,
                        decoration: _m3InputDecoration(context, label: 'Valeur remise', suffixText: _discountType == DiscountType.percent ? '%' : widget.currency),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  if(_discountType == DiscountType.none)
                    const Spacer(),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        
                        if (_scannedCodeGroups.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez scanner au moins un article.'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }

                        // ✅ --- MODIFICATION: On récupère et on convertit la TVA ---
                        final vatPercent = _parseNum(_vatRate.text).toDouble();
                        final vatDecimal = vatPercent / 100.0;

                        final item = LineItem(
                          name: _name.text.trim(),
                          scannedCodeGroups: _scannedCodeGroups,
                          unitPrice: _parseNum(_unitPrice.text).toDouble(),
                          discountType: _discountType,
                          discountValue: _parseNum(_discountValue.text).toDouble(),
                          vatRate: vatDecimal, // On passe le taux en décimal
                          codesPerItem: int.tryParse(_codesPerItemCtrl.text) ?? 1,
                        );
                        Navigator.pop(context, item);
                      },
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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

class _ScanResultTile extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ScanResultTile({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withAlpha(12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(51)),
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Articles Scannés',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appuyez pour commencer le scan',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}