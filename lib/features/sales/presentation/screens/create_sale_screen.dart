// lib/features/sales/presentation/screens/create_sale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_line_entity.dart';
import '../controllers/create_sale_controller.dart';
import '../providers/sales_providers.dart';
import '../widgets/styled_picker_card.dart'; // <-- IMPORT DU NOUVEAU WIDGET

class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  int _step = 0;

  String? _selectedClient;
  DateTime _selectedDate = DateTime.now();
  String? _selectedWarehouse;

  final List<SaleLineEntity> _items = [];
  final List<_Payment> _payments = [];

  double _globalDiscount = 0.0;
  double _shippingFees = 0.0;

  void _next() {
    // Validation pour l'étape 1
    if (_step == 0) {
      if (_selectedClient == null || _selectedWarehouse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un client et un entrepôt.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (_step < 3) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(createSaleControllerProvider);
    final organizationId = ref.watch(organizationIdProvider).value;
    const backgroundColor = Colors.white; // <-- MODIFIÉ ICI

    // Le Scaffold est maintenant commun à toutes les étapes
    return Scaffold(
      backgroundColor: backgroundColor,
      // L'AppBar est maintenant dans le corps pour correspondre au design
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'New Sale (${_step + 1}/4)',
                    style: const TextStyle(
                      color: Color(0xFF1C1C0D),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Pour équilibrer
                ],
              ),
            ),
            // Contenu principal qui change
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(controller, organizationId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ÉTAPE 1 : ENTIÈREMENT RECONSTRUITE ---
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StyledPickerCard(
                  label: 'Client',
                  value: _selectedClient,
                  placeholder: 'Select Client',
                  icon: Icons.expand_more,
                  onTap: () {
                    // TODO: Ouvrir un sélecteur de client
                    setState(() => _selectedClient = 'Client Anonyme');
                  },
                ),
                const SizedBox(height: 24),
                StyledPickerCard(
                  label: 'Date',
                  value:
                      DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDate),
                  placeholder: 'Today',
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 24),
                StyledPickerCard(
                  label: 'Warehouse',
                  value: _selectedWarehouse,
                  placeholder: 'Select Warehouse',
                  icon: Icons.expand_more,
                  onTap: () {
                    // TODO: Ouvrir un sélecteur d'entrepôt
                    setState(() => _selectedWarehouse = 'Entrepôt Principal');
                  },
                ),
              ],
            ),
          ),
        ),
        // Footer avec le bouton "Next"
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Articles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un article'),
              ),
            ],
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
                          "Aucun article. Cliquez sur 'Ajouter' pour commencer.",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item.name ?? 'Article'),
                        subtitle: Text(
                            '${item.quantity} x ${item.unitPrice.toStringAsFixed(0)} F'),
                        trailing:
                            Text('${item.lineTotal.toStringAsFixed(0)} F'),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('Suivant'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final total = _items.fold<double>(0, (sum, e) => sum + e.lineTotal);
    final paid = _payments.fold<double>(0, (sum, p) => sum + p.amount);
    final remaining = total - paid;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total à payer',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${total.toStringAsFixed(0)} F',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paiements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addPayment,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un paiement'),
              ),
            ],
          ),
          Expanded(
            child: _payments.isEmpty
                ? const Center(child: Text('Aucun paiement'))
                : ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final p = _payments[index];
                      return ListTile(
                        title: Text('${p.amount.toStringAsFixed(0)} F'),
                        subtitle: Text(p.method),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _summaryRow('Total payé', paid),
                _summaryRow('Solde restant', remaining, bold: true),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('Suivant'),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final paid = _payments.fold<double>(0, (sum, p) => sum + p.amount);
    final due = grandTotal - paid;

    return Padding(
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
                    final sale = SaleEntity(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      customerId: _selectedClient ?? 'demo',
                      customerName: _selectedClient,
                      createdAt: _selectedDate,
                      items: _items,
                      globalDiscount: _globalDiscount,
                      shippingFees: _shippingFees,
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
          const Spacer(),
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
          Text('${value.toStringAsFixed(0)} F', style: style),
        ],
      ),
    );
  }

  void _addItem() {
    setState(() {
      final index = _items.length + 1;
      _items.add(
        SaleLineEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: 'p$index',
          name: 'Produit $index',
          quantity: 1,
          unitPrice: 1000,
        ),
      );
    });
  }

  void _addPayment() {
    setState(() {
      _payments.add(_Payment(amount: 1000, method: 'Caisse')); // demo
    });
  }
}

class _Payment {
  final double amount;
  final String method;

  _Payment({required this.amount, required this.method});
}