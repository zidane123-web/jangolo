// lib/features/sales/presentation/screens/create_sale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../settings/domain/entities/management_entities.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_line_entity.dart';
import '../controllers/create_sale_controller.dart';
import '../models/payment_view_model.dart';
import '../providers/sales_providers.dart';
import '../widgets/client_picker.dart';
import '../widgets/create_sale/add_payment_dialog.dart';
import '../widgets/create_sale/article_picker.dart';
import '../widgets/create_sale/confirm_exit_dialog.dart';
import '../widgets/create_sale/sale_info_form.dart';
import '../widgets/create_sale/sale_line_dialog.dart';
import 'sale_line_scanner_screen.dart';
import 'simple_barcode_scanner_screen.dart';
import '../../../purchases/presentation/widgets/create_purchase/warehouse_supplier_picker.dart';

class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  int _step = 0;

  ClientEntity? _selectedClient;
  Warehouse? _selectedWarehouse;
  DateTime _selectedDate = DateTime.now();

  final List<SaleLineEntity> _items = [];
  // ✅ MODIFICATION: La liste utilise maintenant le PaymentViewModel
  final List<PaymentViewModel> _payments = [];

  double _globalDiscount = 0.0;
  double _shippingFees = 0.0;

  bool get _isFormDirty {
    return _selectedClient != null ||
        _selectedWarehouse != null ||
        _items.isNotEmpty ||
        _payments.isNotEmpty;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (!_step1FormKey.currentState!.validate()) {
        return;
      }
    }
    if (_step == 1) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins un article à la vente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      for (final item in _items) {
        if (item.isSerialized && item.scannedCodes.length != item.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Veuillez scanner tous les codes pour "${item.name}".'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
    }
    // ✅ La validation de paiement n'est plus bloquante (vente à crédit)
    if (_step < 3) {
      setState(() => _step++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }
  }

  Future<void> _handleClientSelection(List<ClientEntity> clients) async {
    final result = await pickClient(context: context, clients: clients);
    if (result != null) {
      setState(() {
        _selectedClient = result;
      });
    }
  }

  Future<void> _handleWarehouseSelection(List<Warehouse> warehouses) async {
    final result =
        await pickWarehouse(context: context, warehouses: warehouses);
    if (result != null) {
      setState(() {
        _selectedWarehouse = result;
      });
    }
  }

  Future<void> _handleDateSelection() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _addItem() async {
    final selectedArticle = await showArticlePicker(context: context);
    if (selectedArticle == null) return;

    final existingItemIndex =
        _items.indexWhere((item) => item.productId == selectedArticle.id);
    if (existingItemIndex != -1) {
      await _editItem(existingItemIndex, _items[existingItemIndex]);
      return;
    }

    final saleLine =
        await showSaleLineDialog(context: context, article: selectedArticle);
    if (saleLine != null) {
      setState(() {
        _items.add(saleLine);
      });
    }
  }

  Future<void> _scanAndAddItem() async {
    final organizationId = ref.read(organizationIdProvider).value;
    if (organizationId == null) return;

    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SimpleBarcodeScannerScreen()),
    );
    if (scannedCode == null || scannedCode.isEmpty) return;

    final getArticleBySku = ref.read(getArticleBySkuProvider);
    final articleMatch =
        await getArticleBySku(organizationId: organizationId, sku: scannedCode);

    if (articleMatch == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Article non trouvé')));
      }
      return;
    }

    if (articleMatch.hasSerializedUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Cet article doit être ajouté manuellement pour définir la quantité et scanner les codes.")),
      );
      return;
    }

    final existingItemIndex =
        _items.indexWhere((item) => item.productId == articleMatch.id);
    setState(() {
      if (existingItemIndex != -1) {
        final existingLine = _items[existingItemIndex];
        if (existingLine.quantity < articleMatch.totalQuantity) {
          _items[existingItemIndex] = SaleLineEntity(
            id: existingLine.id,
            productId: existingLine.productId,
            name: existingLine.name,
            unitPrice: existingLine.unitPrice,
            quantity: existingLine.quantity + 1,
            isSerialized: existingLine.isSerialized,
            scannedCodes: existingLine.scannedCodes,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Stock maximum atteint pour ${articleMatch.name}')));
        }
      } else {
        if (articleMatch.totalQuantity > 0) {
          _items.add(SaleLineEntity(
            id: '${articleMatch.id}-${DateTime.now().millisecondsSinceEpoch}',
            productId: articleMatch.id,
            name: articleMatch.name,
            quantity: 1,
            unitPrice: articleMatch.sellPrice,
            isSerialized: articleMatch.hasSerializedUnits,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Article ${articleMatch.name} en rupture de stock')));
        }
      }
    });
  }

  Future<void> _editItem(int index, SaleLineEntity line) async {
    final organizationId = ref.read(organizationIdProvider).value;
    if (organizationId == null) return;

    final getArticleBySku = ref.read(getArticleBySkuProvider);
    final originalArticle =
        await getArticleBySku(organizationId: organizationId, sku: line.productId);

    if (originalArticle == null || !mounted) return;

    final updatedLine = await showSaleLineDialog(
      context: context,
      article: originalArticle,
      existingLine: line,
    );

    if (updatedLine != null) {
      setState(() {
        _items[index] = updatedLine;
      });
    }
  }

  Future<void> _scanLineCodes(int index, SaleLineEntity line) async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => SaleLineScannerScreen(
          targetQuantity: line.quantity.toInt(),
          alreadyScannedCodes: line.scannedCodes,
          articleName: line.name ?? 'Article',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _items[index] = SaleLineEntity(
          id: line.id,
          productId: line.productId,
          name: line.name,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          discountType: line.discountType,
          discountValue: line.discountValue,
          vatRate: line.vatRate,
          isSerialized: line.isSerialized,
          scannedCodes: result,
        );
      });
    }
  }

  // ✅ --- NOUVELLE LOGIQUE POUR AJOUTER UN PAIEMENT ---
  Future<void> _addPayment(double amountDue) async {
    final paymentMethods = ref.read(paymentMethodsProvider).value ?? [];
    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucun moyen de paiement configuré.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final result = await showAddPaymentDialog(
      context: context,
      amountDue: amountDue,
      paymentMethods: paymentMethods,
    );

    if (result != null) {
      setState(() {
        _payments.add(result);
      });
    }
  }
  // --- FIN ---

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(createSaleControllerProvider);
    final organizationId = ref.watch(organizationIdProvider).value;
    const backgroundColor = Colors.white;

    final clientsAsync = ref.watch(clientsStreamProvider);
    final warehousesAsync = ref.watch(warehousesProvider);

    return PopScope(
      canPop: !_isFormDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await confirmSaleExit(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Nouvelle Vente (${_step + 1}/4)'),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_isFormDirty) {
                final shouldPop = await confirmSaleExit(context);
                if (shouldPop && context.mounted) Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: clientsAsync.when(
            data: (clients) => warehousesAsync.when(
              data: (warehouses) => PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _step = p),
                children: [
                  _buildStep1(clients, warehouses),
                  _buildStep2(),
                  // ✅ L'étape 3 appelle la nouvelle méthode de build
                  _buildStep3(ref.watch(paymentMethodsProvider).value ?? []),
                  _buildStep4(controller, organizationId),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Erreur entrepôts: $e")),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Erreur clients: $e")),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(List<ClientEntity> clients, List<Warehouse> warehouses) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Form(
              key: _step1FormKey,
              child: SaleInfoForm(
                client: _selectedClient?.name,
                onClientTap: () => _handleClientSelection(clients),
                warehouse: _selectedWarehouse?.name,
                onWarehouseTap: () => _handleWarehouseSelection(warehouses),
                saleDate: _selectedDate,
                onSaleDateTap: _handleDateSelection,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Suivant'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Articles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FilledButton.tonalIcon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shopping_basket_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Ajoutez un article pour commencer.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    Widget tile;
                    if (item.isSerialized) {
                      tile = _SerializedSaleLineTile(
                        item: item,
                        onScan: () => _scanLineCodes(index, item),
                        onEdit: () => _editItem(index, item),
                      );
                    } else {
                      tile = _StandardSaleLineTile(
                        item: item,
                        onEdit: () => _editItem(index, item),
                      );
                    }

                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() => _items.removeAt(index));
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      child: tile,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sous-total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${NumberFormat.decimalPattern('fr_FR').format(subtotal)} F',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(onPressed: _back, child: const Text('Retour')),
                  const Spacer(),
                  FilledButton(onPressed: _next, child: const Text('Suivant')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ --- MÉTHODE _buildStep3 COMPLÈTEMENT REFAITE ---
  Widget _buildStep3(List<PaymentMethod> paymentMethods) {
    final theme = Theme.of(context);
    final total = _items.fold<double>(0, (sum, e) => sum + e.lineTotal);
    final paid =
        _payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
    final due = total - paid;
    final change = _payments.fold<double>(0, (sum, p) => sum + p.change);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PaymentSummaryCard(
                  total: total,
                  paid: paid,
                  due: due,
                  change: change,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paiements Encaissés',
                        style: theme.textTheme.titleLarge),
                    if (due > 0.01)
                      FilledButton.tonalIcon(
                        onPressed: () => _addPayment(due),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_payments.isEmpty)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('Aucun paiement pour le moment.'),
                  ))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          title: Text(_money(payment.amountPaid)),
                          subtitle: Text('Via: ${payment.method.name}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: theme.colorScheme.error),
                            onPressed: () {
                              setState(() => _payments.removeAt(index));
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              OutlinedButton(onPressed: _back, child: const Text('Retour')),
              const Spacer(),
              FilledButton(onPressed: _next, child: const Text('Suivant')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4(
    CreateSaleController controller,
    String? organizationId,
  ) {
    final subTotal =
        _items.fold<double>(0, (sum, e) => sum + e.lineSubtotal);
    final discountTotal =
        _items.fold<double>(0, (sum, e) => sum + e.lineDiscount) +
            _globalDiscount;
    final taxTotal = _items.fold<double>(0, (sum, e) => sum + e.lineTax);
    final grandTotal = subTotal - _globalDiscount + taxTotal + _shippingFees;
    final paid =
        _payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
    final due = grandTotal - paid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Résumé",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Sous-total', subTotal),
                  _summaryRow('Remises', discountTotal),
                  _summaryRow('TVA', taxTotal),
                  _summaryRow('Frais de livraison', _shippingFees),
                  const Divider(),
                  _summaryRow('Total général', grandTotal, bold: true),
                  _summaryRow('Total payé', paid),
                  _summaryRow('Solde dû', due),
                ],
              ),
            ),
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Remise globale'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() => _globalDiscount = double.tryParse(value) ?? 0.0);
            },
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Frais de livraison'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() => _shippingFees = double.tryParse(value) ?? 0.0);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: organizationId == null
                ? null
                : () async {
                    if (_selectedClient == null) return;
                    final sale = SaleEntity(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      customerId: _selectedClient!.id,
                      customerName: _selectedClient!.name,
                      createdAt: _selectedDate,
                      items: _items,
                      globalDiscount: _globalDiscount,
                      shippingFees: _shippingFees,
                      // TODO: Convertir PaymentViewModel en PaymentEntity
                      payments: const [], 
                    );
                    await controller.saveSale(
                      organizationId: organizationId,
                      sale: sale,
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: const Text('Valider la Vente'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Enregistrer comme Brouillon'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _back,
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(_money(value), style: style),
        ],
      ),
    );
  }
}

// ✅ --- NOUVEAUX WIDGETS POUR L'UI DE PAIEMENT ---

class _PaymentSummaryCard extends StatelessWidget {
  final double total;
  final double paid;
  final double due;
  final double change;

  const _PaymentSummaryCard({
    required this.total,
    required this.paid,
    required this.due,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _SummaryRow(label: 'Total de la vente', value: _money(total)),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Montant Reçu', value: _money(paid)),
            if (change > 0) ...[
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Monnaie à rendre',
                value: _money(change),
                valueColor: Colors.green.shade700,
              ),
            ],
            const Divider(height: 24),
            _SummaryRow(
              label: due > 0 ? 'Solde Restant' : 'Crédit',
              value: _money(due.abs()),
              isBold: true,
              valueColor: due > 0.01 ? theme.colorScheme.error : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = isBold
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyLarge;
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: valueColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle)
      ],
    );
  }
}
// --- FIN DES NOUVEAUX WIDGETS ---

String _money(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
        .format(v);

class _StandardSaleLineTile extends StatelessWidget {
  final SaleLineEntity item;
  final VoidCallback onEdit;
  const _StandardSaleLineTile({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(item.name ?? 'Article'),
        subtitle: Text(
            '${item.quantity.toStringAsFixed(0)} x ${_money(item.unitPrice)}'),
        trailing: Text(
          _money(item.lineTotal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _SerializedSaleLineTile extends StatelessWidget {
  final SaleLineEntity item;
  final VoidCallback onScan;
  final VoidCallback onEdit;
  const _SerializedSaleLineTile(
      {required this.item, required this.onScan, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scannedCount = item.scannedCodes.length;
    final targetCount = item.quantity.toInt();
    final isComplete = scannedCount == targetCount;
    final color = isComplete
        ? Colors.green
        : (scannedCount > 0 ? Colors.orange : theme.colorScheme.primary);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              dense: true,
              title: Text(item.name ?? 'Article',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$targetCount x ${_money(item.unitPrice)}'),
              trailing: Text(
                _money(item.lineTotal),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: onEdit,
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: Icon(Icons.qr_code_2_rounded, color: color),
              title: Text('Codes scannés: $scannedCount / $targetCount',
                  style: TextStyle(color: color)),
              trailing: Icon(
                  isComplete
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward_ios_rounded,
                  color: color),
              onTap: onScan,
            ),
          ],
        ),
      ),
    );
  }
}
