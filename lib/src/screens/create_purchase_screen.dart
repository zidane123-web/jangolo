import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ➜ importe la page d’édition de ligne et les types partagés
import 'purchase_line_edit_screen.dart';

/// Page de création d’un Bon d’Achat (marchandises)
/// Design Material 3, sections en cartes, page dédiée pour ajouter/éditer une ligne,
/// calculs de totaux (remise, TVA, transport, autres frais).
class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  // --------- Champs entête
  final _supplierCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _paymentTermsCtrl = TextEditingController(text: '30 jours fin de mois');
  final _shippingCtrl = TextEditingController(text: '0');
  final _otherFeesCtrl = TextEditingController(text: '0');

  DateTime _orderDate = DateTime.now();
  DateTime _etaDate = DateTime.now().add(const Duration(days: 7));
  String? _warehouse = 'Entrepôt Cotonou';
  String _currency = 'F';
  double _globalDiscount = 0; // Remise globale (monétaire)
  double _globalVatRate = 0.18; // TVA par défaut 18%

  final List<LineItem> _items = [];

  // --------- Formatters & utils
  final _nf = NumberFormat("#,##0.00", "fr_FR");

  String _money(num v) => "${_nf.format(v)} $_currency";
  String _date(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);

  // --------- Calculs
  num get _subTotal => _items.fold<num>(0, (s, it) => s + it.lineSubtotal);
  num get _discountTotal =>
      _items.fold<num>(0, (s, it) => s + it.lineDiscount) + _globalDiscount;
  num get _taxableBase => (_subTotal - _discountTotal).clamp(0, double.infinity);
  num get _taxTotal => (_taxableBase * _globalVatRate);
  num get _shipping => _parseNum(_shippingCtrl.text);
  num get _otherFees => _parseNum(_otherFeesCtrl.text);
  num get _grandTotal => (_taxableBase + _taxTotal + _shipping + _otherFees);

  num _parseNum(String v) {
    final clean = v.replaceAll(' ', '').replaceAll(',', '.');
    return num.tryParse(clean) ?? 0;
  }

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _referenceCtrl.dispose();
    _noteCtrl.dispose();
    _paymentTermsCtrl.dispose();
    _shippingCtrl.dispose();
    _otherFeesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choisir une date',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _addOrEditItem({LineItem? current, int? index}) async {
    final result = await Navigator.of(context).push<LineItem>(
      MaterialPageRoute(
        builder: (_) => PurchaseLineEditScreen(
          initial: current,
          currency: _currency,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _items[index] = result;
        } else {
          _items.add(result);
        }
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _save({required bool approve}) {
    if (!_formKey.currentState!.validate()) {
      _snack('Veuillez compléter les champs obligatoires.');
      return;
    }
    if (_items.isEmpty) {
      _snack('Ajoutez au moins une ligne d’article.');
      return;
    }

    _snack(approve
        ? 'Bon d’achat validé — Total ${_money(_grandTotal)}'
        : 'Brouillon enregistré — Total ${_money(_grandTotal)}');

    Navigator.of(context).pop(); // retourne à la liste
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Nouvel achat de marchandises'),
        elevation: 0.6,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Aide',
            onPressed: () => _snack('Aide à venir'),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: CustomScrollView(
            slivers: [
              // Section : Entête & Fournisseur
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SectionCard(
                    title: 'Informations fournisseur',
                    subtitle:
                        'Identifiez le fournisseur et les détails principaux du bon.',
                    child: Column(
                      children: [
                        _LabeledTextField(
                          controller: _supplierCtrl,
                          label: 'Fournisseur *',
                          hint: 'Ex. TechDistrib SARL',
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requis' : null,
                          prefixIcon: Icons.store_mall_directory_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DropdownField<String>(
                                label: 'Entrepôt *',
                                value: _warehouse,
                                items: const [
                                  'Entrepôt Cotonou',
                                  'Magasin Porto-Novo',
                                  'Dépôt Parakou',
                                ],
                                onChanged: (v) => setState(() => _warehouse = v),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Requis' : null,
                                prefixIcon: Icons.home_work_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledTextField(
                                controller: _referenceCtrl,
                                label: 'Référence',
                                hint: 'Ex. PO-2025-0098',
                                textInputAction: TextInputAction.next,
                                prefixIcon: Icons.tag_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: 'Date de commande *',
                                value: _date(_orderDate),
                                onTap: () => _pickDate(
                                  initial: _orderDate,
                                  onPicked: (d) => setState(() => _orderDate = d),
                                ),
                                prefixIcon: Icons.event_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateField(
                                label: 'Date prévue (ETA)',
                                value: _date(_etaDate),
                                onTap: () => _pickDate(
                                  initial: _etaDate,
                                  onPicked: (d) => setState(() => _etaDate = d),
                                ),
                                prefixIcon: Icons.schedule_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _LabeledTextField(
                          controller: _paymentTermsCtrl,
                          label: 'Conditions de paiement',
                          hint: 'Ex. 30 jours fin de mois',
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section : Lignes d’articles (ouvre une page dédiée)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SectionCard(
                    title: 'Lignes d’articles',
                    subtitle:
                        'Ajoutez les produits, quantités, prix, remises et TVA par ligne.',
                    trailing: FilledButton.icon(
                      onPressed: () => _addOrEditItem(),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une ligne'),
                    ),
                    child: _items.isEmpty
                        ? _Empty(
                            icon: Icons.playlist_add_outlined,
                            text:
                                'Aucune ligne. Ajoutez vos articles à l’aide du bouton ci-dessus.',
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            primary: false,
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 24),
                            itemBuilder: (context, i) {
                              final it = _items[i];
                              return _LineTile(
                                item: it,
                                currency: _currency,
                                onEdit: () =>
                                    _addOrEditItem(current: it, index: i),
                                onDelete: () => _removeItem(i),
                              );
                            },
                          ),
                  ),
                ),
              ),

              // Section : Remises & TVA globale
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SectionCard(
                    title: 'Remises & TVA',
                    subtitle: 'Ajustez la remise globale et le taux de TVA.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MoneyField(
                                controllerText: _globalDiscount == 0
                                    ? ''
                                    : _nf.format(_globalDiscount),
                                label: 'Remise globale',
                                hint: '0,00',
                                onChangedNum: (v) =>
                                    setState(() => _globalDiscount = v.toDouble()),
                                prefixIcon: Icons.local_offer_outlined,
                                currency: _currency,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DropdownField<double>(
                                label: 'TVA',
                                value: _globalVatRate,
                                items: const [0.0, 0.05, 0.10, 0.18, 0.20],
                                itemBuilder: (v) =>
                                    '${(v * 100).toStringAsFixed(0)} %',
                                onChanged: (v) =>
                                    setState(() => _globalVatRate = v ?? 0.0),
                                prefixIcon: Icons.percent_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section : Frais & Notes
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SectionCard(
                    title: 'Frais & notes',
                    subtitle:
                        'Ajoutez les frais de transport, autres frais et une note interne.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MoneyField(
                                controller: _shippingCtrl,
                                label: 'Transport',
                                hint: '0,00',
                                onChangedNum: (_) => setState(() {}),
                                prefixIcon: Icons.local_shipping_outlined,
                                currency: _currency,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MoneyField(
                                controller: _otherFeesCtrl,
                                label: 'Autres frais',
                                hint: '0,00',
                                onChangedNum: (_) => setState(() {}),
                                prefixIcon: Icons.request_quote_outlined,
                                currency: _currency,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _LabeledTextField(
                          controller: _noteCtrl,
                          label: 'Note interne',
                          hint: 'Ajouter une note pour l’équipe achat...',
                          maxLines: 3,
                          prefixIcon: Icons.sticky_note_2_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // --- Section Totaux et Actions ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      _SummaryHeader(
                        currency: _currency,
                        subTotal: _subTotal,
                        taxTotal: _taxTotal,
                        grandTotal: _grandTotal,
                        onCurrencyTap: () => _chooseCurrency(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _save(approve: false),
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Enregistrer (brouillon)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _save(approve: true),
                              icon: const Icon(Icons.verified_outlined),
                              label: const Text('Valider la commande'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseCurrency() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _CurrencySheet(current: _currency),
    );
    if (result != null) {
      setState(() => _currency = result);
    }
  }
}

// -----------------------------------------------------------------------------
// Widgets — Sections & Entrées
// -----------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ]
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
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
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.itemBuilder,
    this.onChanged,
    this.validator,
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
      validator: validator,
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? prefixIcon;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) { 
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(value),
        ),
      ),
    );
  }
}

class _MoneyField extends StatefulWidget {
  final TextEditingController? controller;
  final String? controllerText; // initialise sans créer un controller externe
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String currency;
  final ValueChanged<num>? onChangedNum;

  const _MoneyField({
    this.controller,
    this.controllerText,
    required this.label,
    this.hint,
    this.prefixIcon,
    required this.currency,
    this.onChangedNum,
  });

  @override
  State<_MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<_MoneyField> {
  late final TextEditingController _ctrl =
      widget.controller ?? TextEditingController(text: widget.controllerText);

  num _parseNum(String v) {
    final clean = v.replaceAll(' ', '').replaceAll(',', '.');
    return num.tryParse(clean) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,\.\s]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixText: widget.currency,
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (v) => widget.onChangedNum?.call(_parseNum(v)),
    );
  }
}

// -----------------------------------------------------------------------------
// Liste — tuile de ligne + bandeau totaux + devise
// -----------------------------------------------------------------------------

class _LineTile extends StatelessWidget {
  final LineItem item;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LineTile({
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

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withOpacity(0.1), // ok même si déprécié
            child: const Icon(Icons.inventory_2_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: tt.bodyMedium!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.sku?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('SKU: ${item.sku}',
                          style: tt.bodySmall?.copyWith(color: cs.outline)),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _ChipInfo(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Qté',
                          value: nf.format(item.qty)),
                      _ChipInfo(
                          icon: Icons.payments_outlined,
                          label: 'PU',
                          value: money(item.unitPrice)),
                      if (item.discountType != DiscountType.none)
                        _ChipInfo(
                            icon: Icons.local_offer_outlined,
                            label: 'Remise',
                            value: item.discountType == DiscountType.percent
                                ? '${item.discountValue.toStringAsFixed(0)} %'
                                : money(item.discountValue)),
                      _ChipInfo(
                          icon: Icons.percent_outlined,
                          label: 'TVA',
                          value:
                              '${(item.vatRate * 100).toStringAsFixed(0)} %'),
                      _ChipInfo(
                          icon: Icons.calculate_outlined,
                          label: 'Sous-total',
                          value: money(item.lineSubtotal)),
                      _ChipInfo(
                          icon: Icons.receipt_long_outlined,
                          label: 'Total',
                          value: money(item.lineTotal)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton(
                tooltip: 'Modifier',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ChipInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: tt.labelMedium
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
          ),
          Text(value, style: tt.labelMedium),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String currency;
  final num subTotal;
  final num taxTotal;
  final num grandTotal;
  final VoidCallback onCurrencyTap;

  const _SummaryHeader({
    required this.currency,
    required this.subTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.onCurrencyTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nf = NumberFormat("#,##0.00", "fr_FR");
    String money(num v) => "${nf.format(v)} $currency";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.25),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      _KpiMini(label: 'Sous-total', value: money(subTotal))),
              const SizedBox(width: 12),
              Expanded(child: _KpiMini(label: 'TVA', value: money(taxTotal))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiMini(
                  label: 'Devise',
                  value: currency,
                  trailing: TextButton.icon(
                    onPressed: onCurrencyTap,
                    icon: const Icon(Icons.currency_exchange),
                    label: const Text('Changer'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiMini(
                  label: 'Total à payer',
                  value: money(grandTotal),
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiMini extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Widget? trailing;

  const _KpiMini({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final style = emphasize
        ? tt.titleLarge?.copyWith(fontWeight: FontWeight.w900)
        : tt.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: tt.labelMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 2),
              Text(value, style: style),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CurrencySheet extends StatelessWidget {
  final String current;
  const _CurrencySheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = ['F', '€', r'$'];
    return ListView(
      shrinkWrap: true,
      children: [
        const ListTile(
          title: Text('Choisir une devise',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        const Divider(height: 0),
        ...options.map(
          (c) => RadioListTile<String>(
            value: c,
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
            title: Text(c),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}