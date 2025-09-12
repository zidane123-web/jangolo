// lib/features/sales/presentation/screens/create_sale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_line_entity.dart';
import '../controllers/create_sale_controller.dart';
import '../providers/sales_providers.dart';
// --- NOUVEAUX IMPORTS ---
import '../../../settings/domain/entities/management_entities.dart';
import '../../domain/entities/client_entity.dart';
import '../widgets/client_picker.dart';
import '../../../purchases/presentation/widgets/create_purchase/warehouse_supplier_picker.dart';
import '../widgets/create_sale/sale_info_form.dart';

class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  // --- GESTION D'ÉTAT AMÉLIORÉE ---
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  int _step = 0;

  // Modèles de données au lieu de simples chaînes de caractères
  ClientEntity? _selectedClient;
  Warehouse? _selectedWarehouse;
  DateTime _selectedDate = DateTime.now();

  final List<SaleLineEntity> _items = [];
  final List<_Payment> _payments = [];

  double _globalDiscount = 0.0;
  double _shippingFees = 0.0;

  // --- DONNÉES FICTIVES POUR LA DÉMO ---
  final List<ClientEntity> _dummyClients = [
    const ClientEntity(id: 'CUST-001', name: 'Client Fidèle SARL'),
    const ClientEntity(id: 'CUST-002', name: 'Nouveau Visiteur'),
    const ClientEntity(id: 'CUST-003', name: 'Boutique du Coin'),
  ];
  final List<Warehouse> _dummyWarehouses = [
    const Warehouse(id: 'WH-001', name: 'Entrepôt Principal'),
    const Warehouse(id: 'WH-002', name: 'Magasin Central'),
  ];
  // --- FIN DES DONNÉES FICTIVES ---

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    // Validation améliorée pour l'étape 1
    if (_step == 0) {
      if (!_step1FormKey.currentState!.validate()) {
        return; // Le formulaire affiche les erreurs
      }
    }
    // Validation pour l'étape 2 (articles)
    if (_step == 1 && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un article à la vente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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

  // --- NOUVELLES FONCTIONS DE SÉLECTION ---
  Future<void> _handleClientSelection() async {
    final result = await pickClient(context: context, clients: _dummyClients);
    if (result != null) {
      setState(() {
        _selectedClient = result;
        // Si le client vient d'être créé, on l'ajoute à notre liste fictive
        if (!_dummyClients.any((c) => c.id == result.id)) {
          _dummyClients.add(result);
        }
      });
    }
  }

  Future<void> _handleWarehouseSelection() async {
    // On réutilise le picker des achats, mais avec nos données fictives
    final result = await pickWarehouse(context: context, warehouses: _dummyWarehouses);
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
  // --- FIN DES NOUVELLES FONCTIONS ---

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(createSaleControllerProvider);
    final organizationId = ref.watch(organizationIdProvider).value;
    const backgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Nouvelle Vente (${_step + 1}/4)'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (p) => setState(() => _step = p),
          children: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
            _buildStep4(controller, organizationId),
          ],
        ),
      ),
    );
  }

  // --- ÉTAPE 1 : ENTIÈREMENT RECONSTRUITE AVEC LE FORMULAIRE ---
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Form(
              key: _step1FormKey,
              child: SaleInfoForm(
                client: _selectedClient?.name,
                onClientTap: _handleClientSelection,
                warehouse: _selectedWarehouse?.name,
                onWarehouseTap: _handleWarehouseSelection,
                saleDate: _selectedDate,
                onSaleDateTap: _handleDateSelection,
              ),
            ),
          ),
        ),
        // Footer avec le bouton "Suivant"
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Suivant'),
            ),
          ),
        ),
      ],
    );
  }

  // Les autres étapes (_buildStep2, _buildStep3, _buildStep4) restent
  // globalement les mêmes, mais la sauvegarde dans _buildStep4 doit être mise à jour
  // pour utiliser les nouveaux objets.

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
                        Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey),
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
                        subtitle: Text('${item.quantity} x ${item.unitPrice.toStringAsFixed(0)} F'),
                        trailing: Text('${item.lineTotal.toStringAsFixed(0)} F'),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                OutlinedButton(onPressed: _back, child: const Text('Retour')),
                const Spacer(),
                FilledButton(onPressed: _next, child: const Text('Suivant')),
              ],
            ),
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
                  const Text('Total à payer', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${total.toStringAsFixed(0)} F', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                OutlinedButton(onPressed: _back, child: const Text('Retour')),
                const Spacer(),
                FilledButton(onPressed: _next, child: const Text('Suivant')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(
    CreateSaleController controller,
    String? organizationId,
  ) {
    final subTotal = _items.fold<double>(0, (sum, e) => sum + e.lineSubtotal);
    final discountTotal =
        _items.fold<double>(0, (sum, e) => sum + e.lineDiscount) + _globalDiscount;
    final taxTotal = _items.fold<double>(0, (sum, e) => sum + e.lineTax);
    final grandTotal = subTotal - _globalDiscount + taxTotal + _shippingFees;
    final paid = _payments.fold<double>(0, (sum, p) => sum + p.amount);
    final due = grandTotal - paid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Résumé", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
