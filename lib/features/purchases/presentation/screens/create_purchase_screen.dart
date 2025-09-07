// lib/features/purchases/presentation/screens/create_purchase_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORTS DE L'ARCHITECTURE ---
import '../../../settings/domain/entities/management_entities.dart';
import '../../../settings/presentation/screens/add_edit_warehouse_screen.dart';
import '../../../settings/presentation/screens/add_supplier_screen.dart';

// --- LOGIQUE DU FORMULAIRE ---
import '../controllers/create_purchase_controller.dart';

// --- IMPORTS DE L'UI ---
import 'purchase_line_edit_screen.dart';
import '../models/payment_view_model.dart';
import '../widgets/create_purchase/supplier_info_form.dart';
import '../widgets/create_purchase/line_items_section.dart';
import '../widgets/create_purchase/purchase_summary_card.dart';
import '../widgets/create_purchase/payment_and_reception_step.dart';

class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  late final PageController _pageController;
  int _currentStep = 0;
  
  // --- GESTION DE L'ÉTAT DE L'ECRAN ---
  bool _isLoading = true;
  String? _loadingError;
  
  // --- ETATS DU FORMULAIRE ---
  Supplier? _supplier;
  Warehouse? _warehouse;
  DateTime _orderDate = DateTime.now();
  final List<LineItem> _items = [];
  ReceptionStatusChoice _receptionChoice = ReceptionStatusChoice.toReceive;
  final List<PaymentViewModel> _payments = [];
  
  // --- Listes dynamiques qui seront remplies depuis Firebase ---
  List<Supplier> _suppliers = [];
  List<Warehouse> _warehouses = [];
  List<PaymentMethod> _paymentMethods = [];

  final String _currency = 'F';
  bool _isSaving = false;
  
  // --- Instances pour la logique métier ---
  late final CreatePurchaseController _controller;
  late final DateTime _initialOrderDate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initialOrderDate = _orderDate;
    _controller = CreatePurchaseController();

    // --- Lancement du chargement des données ---
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final data = await _controller.loadInitialData();
      if (!mounted) return;
      setState(() {
        _suppliers = data.suppliers;
        _warehouses = data.warehouses;
        _paymentMethods = data.paymentMethods;
        if (_warehouses.isNotEmpty) {
          _warehouse = _warehouses.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingError = "Erreur de chargement: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  bool get _isFormDirty {
    return _supplier != null ||
        _warehouse != null ||
        _items.isNotEmpty ||
        _payments.isNotEmpty ||
        _receptionChoice != ReceptionStatusChoice.toReceive ||
        _orderDate != _initialOrderDate;
  }

  Future<void> _save({required bool approve}) async {
    setState(() => _isSaving = true);
    try {
      await _controller.savePurchase(
        supplier: _supplier!,
        warehouse: _warehouse!,
        orderDate: _orderDate,
        items: _items,
        payments: _payments,
        paymentMethods: _paymentMethods,
        receptionChoice: _receptionChoice,
        approve: approve,
      );

      if (mounted) {
        _snack(approve ? 'Bon d’achat validé !' : 'Brouillon enregistré.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _snack('Erreur lors de la sauvegarde: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  Future<void> _showAddPaymentDialog() async {
    final grandTotal =
        _items.fold<double>(0.0, (total, item) => total + item.lineTotal.toDouble());
    final totalPaidSoFar =
        _payments.fold(0.0, (total, p) => total + p.amount);
    final amountController = TextEditingController();
    PaymentMethod? selectedMethod =
        _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<PaymentViewModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un paiement'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Montant',
                    suffixText: _currency,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final parsed = double.tryParse(v) ?? 0;
                    if (parsed <= 0) return 'Montant invalide';
                    if (parsed > grandTotal - totalPaidSoFar) {
                      return 'Dépasse le solde';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Moyen de paiement',
                    border: OutlineInputBorder(),
                  ),
                  items: _paymentMethods
                      .map((method) =>
                          DropdownMenuItem(value: method, child: Text(method.name)))
                      .toList(),
                  onChanged: (v) => selectedMethod = v,
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    PaymentViewModel(
                      amount: double.parse(amountController.text),
                      method: selectedMethod!.name,
                    ),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    amountController.dispose();

    if (result != null) {
      setState(() {
        _payments.add(result);
      });
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : null,
    ));
  }

  Future<void> _pickOrderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _orderDate = picked);
  }

  void _showWarehousePicker() {
    _showStyledPicker(
      context: context,
      title: 'Sélectionner un entrepôt',
      items: _warehouses.map((e) => e.name).toList(),
      icon: Icons.home_work_outlined,
      onSelected: (selectedName) {
        setState(() => _warehouse = _warehouses.firstWhere((w) => w.name == selectedName));
        Navigator.pop(context);
      },
      actionButton: TextButton(
        onPressed: () async {
          Navigator.pop(context);
          final newWarehouseResult = await Navigator.of(context).push<Warehouse>(
            MaterialPageRoute(builder: (_) => const AddEditWarehouseScreen()),
          );

          if (newWarehouseResult != null) {
            try {
              final savedWarehouse = await _controller.addWarehouse(
                name: newWarehouseResult.name,
                address: newWarehouseResult.address,
              );
              setState(() {
                _warehouses.add(savedWarehouse);
                _warehouse = savedWarehouse;
              });
            } catch (e) {
              _snack("Erreur de sauvegarde de l'entrepôt: $e", isError: true);
            }
          }
        },
        child: const Text('Créer'),
      ),
    );
  }
  
  void _showSupplierPicker() {
    _showStyledPicker(
      context: context,
      title: 'Sélectionner un fournisseur',
      items: _suppliers.map((e) => e.name).toList(),
      icon: Icons.store_mall_directory_outlined,
      onSelected: (selectedName) {
        setState(() => _supplier = _suppliers.firstWhere((s) => s.name == selectedName));
        Navigator.pop(context);
      },
      actionButton: TextButton(
        onPressed: () async {
          Navigator.pop(context);
          final newSupplierResult = await Navigator.of(context).push<Supplier>(
            MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
          );

          if (newSupplierResult != null) {
            try {
              final savedSupplier = await _controller.addSupplier(
                name: newSupplierResult.name,
                phone: newSupplierResult.phone,
              );
              setState(() {
                _suppliers.add(savedSupplier);
                _supplier = savedSupplier;
              });
            } catch (e) {
              _snack("Erreur de sauvegarde du fournisseur: $e", isError: true);
            }
          }
        },
        child: const Text('Créer'),
      ),
    );
  }

  Future<void> _addOrEditItem({LineItem? current, int? index}) async {
    final result = await Navigator.of(context).push<LineItem>(
      MaterialPageRoute(
        builder: (_) =>
            PurchaseLineEditScreen(initial: current, currency: _currency),
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

  Future<void> _removeItem(int index) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer cet article ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (shouldDelete) {
      setState(() => _items.removeAt(index));
    }
  }
  
  void _onNext() {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep == 1 && _items.isEmpty) {
      _snack('Veuillez ajouter au moins un article.', isError: true);
      return;
    }

    if (_currentStep == 2 && _payments.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirmation requise"),
          content: const Text("Aucun paiement n'a été enregistré. Voulez-vous marquer cet achat comme 'Non Payé' et continuer ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Non, rester'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
              },
              child: const Text('Oui, continuer'),
            ),
          ],
        ),
      );
      return;
    }
    
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFormDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final bool shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Abandonner l\'achat ?'),
            content: const Text('Toutes les données saisies seront perdues.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Rester'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Abandonner'),
              ),
            ],
          ),
        ) ?? false;

        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('Nouvel Achat (${_currentStep + 1}/4)'),
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadingError != null
                    ? Center(child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_loadingError!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ))
                    : PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (page) => setState(() => _currentStep = page),
                        children: [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4()],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          Form(
            key: _step1FormKey,
            child: SupplierInfoForm(
              supplier: _supplier?.name,
              onSupplierTap: _showSupplierPicker,
              warehouse: _warehouse?.name,
              onWarehouseTap: _showWarehousePicker,
              orderDate: DateFormat('dd/MM/yyyy', 'fr_FR').format(_orderDate),
              onOrderDateTap: _pickOrderDate,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _onNext,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Suivant'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: LineItemsSection(
              items: _items,
              currency: _currency,
              onAddItem: () => _addOrEditItem(),
              onEditItem: (item, index) =>
                  _addOrEditItem(current: item, index: index),
              onRemoveItem: _removeItem,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                OutlinedButton(onPressed: _onBack, child: const Text('Retour')),
                const Spacer(),
                FilledButton(onPressed: _onNext, child: const Text('Suivant')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final grandTotal = _items.fold<double>(0.0, (total, item) => total + item.lineTotal.toDouble());
    return Column(
      children: [
        Expanded(
          child: PaymentAndReceptionStep(
            grandTotal: grandTotal,
            currency: _currency,
            payments: _payments,
            onAddPayment: _showAddPaymentDialog,
            onRemovePayment: (index) => setState(() => _payments.removeAt(index)),
            receptionStatus: _receptionChoice,
            onReceptionStatusChanged: (choice) => setState(() => _receptionChoice = choice),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              OutlinedButton(onPressed: _onBack, child: const Text('Retour')),
              const Spacer(),
              FilledButton(onPressed: _onNext, child: const Text('Suivant')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          PurchaseSummaryCard(
            grandTotal: _items.fold<double>(0.0, (total, item) => total + item.lineTotal.toDouble()),
            currency: _currency,
          ),
          const SizedBox(height: 32),
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _onBack, child: const Text('Retour')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _save(approve: true),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Valider la Commande'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isSaving ? null : () => _save(approve: false),
              child: const Text('Enregistrer comme brouillon'),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ --- DÉBUT DE LA CORRECTION ---
// La fonction est transformée en une méthode qui affiche un widget dédié.
void _showStyledPicker({
  required BuildContext context,
  required String title,
  required List<String> items,
  required IconData icon,
  required ValueChanged<String> onSelected,
  Widget? actionButton,
}) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    showDragHandle: true,
    builder: (context) {
      return _StyledPickerSheet(
        title: title,
        items: items,
        icon: icon,
        onSelected: onSelected,
        actionButton: actionButton,
      );
    },
  );
}

// Nouveau widget Stateful pour gérer correctement l'état de la feuille modale.
class _StyledPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onSelected;
  final Widget? actionButton;

  const _StyledPickerSheet({
    required this.title,
    required this.items,
    required this.icon,
    required this.onSelected,
    this.actionButton,
  });

  @override
  State<_StyledPickerSheet> createState() => _StyledPickerSheetState();
}

class _StyledPickerSheetState extends State<_StyledPickerSheet> {
  late final TextEditingController _searchController;
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Permet au contenu de ne pas être caché par le clavier
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.title, style: theme.textTheme.titleLarge),
              ),
              if (widget.actionButton != null) widget.actionButton!,
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // La ListView doit être dans un Flexible pour éviter l'overflow
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(153)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withAlpha(25),
                      child: Icon(widget.icon, size: 20),
                    ),
                    title: Text(item,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    onTap: () => widget.onSelected(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
