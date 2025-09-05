// lib/features/purchases/presentation/screens/create_purchase_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_line_entity.dart';
import '../../domain/usecases/create_purchase.dart';

import 'purchase_line_edit_screen.dart';
import '../models/payment_view_model.dart';
import '../widgets/create_purchase/supplier_info_form.dart';
import '../widgets/create_purchase/line_items_section.dart';
import '../widgets/create_purchase/purchase_summary_card.dart';
import '../widgets/create_purchase/payment_and_reception_step.dart';


enum ReceptionStatusChoice { toReceive, alreadyReceived }

class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  late final PageController _pageController;
  int _currentStep = 0;
  
  // --- ETAT ETAPE 1 ---
  String? _supplier;
  DateTime _orderDate = DateTime.now();
  String? _warehouse = 'Entrepôt Cotonou';
  
  // --- ETAT ETAPE 2 ---
  final List<LineItem> _items = [];
  
  // ✅ --- CORRECTION: Les anciens états de paiement sont supprimés ---
  ReceptionStatusChoice _receptionChoice = ReceptionStatusChoice.toReceive;
  final List<PaymentViewModel> _payments = [];
  final _paymentMethods = const ['Caisse', 'Banque', 'Mobile Money'];

  final _suppliers = const [
    'TechDistrib SARL', 'Global Imports SA', 'Phone Accessoires Plus',
    'Innovations Mobiles', 'Électro Fourniture Express'
  ];
  final _warehouses = const ['Entrepôt Cotonou', 'Magasin Porto-Novo', 'Dépôt Parakou'];
  final String _currency = 'F';
  bool _isSaving = false;
  late final CreatePurchase _createPurchase;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final remoteDataSource = PurchaseRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository = PurchaseRepositoryImpl(remoteDataSource: remoteDataSource);
    _createPurchase = CreatePurchase(repository);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  bool get _isFormDirty => _supplier != null || _items.isNotEmpty;

  Future<void> _save({required bool approve}) async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté.");
      final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
      final organizationId = userDoc.data()?['organizationId'] as String?;
      if (organizationId == null) throw Exception("Organisation non trouvée.");

      final grandTotal = _items.fold<double>(0.0, (total, item) => total + item.lineTotal.toDouble());
      final totalPaid = _payments.fold(0.0, (total, p) => total + p.amount);
      
      final List<PaymentEntity> paymentEntities = _payments.map((p) => PaymentEntity(
        id: UniqueKey().toString(),
        amount: p.amount,
        date: DateTime.now(),
        paymentMethod: p.method,
        treasuryAccountId: p.method,
      )).toList();

      final bool isFullyPaid = (grandTotal > 0) && (grandTotal - totalPaid).abs() < 0.01;
      PurchaseStatus status;

      if (!approve) {
        status = PurchaseStatus.draft;
      } else if (_receptionChoice == ReceptionStatusChoice.alreadyReceived && isFullyPaid) {
        status = PurchaseStatus.paid;
      } else if (_receptionChoice == ReceptionStatusChoice.alreadyReceived) {
        status = PurchaseStatus.received;
      } else {
        status = PurchaseStatus.approved;
      }

      final newPurchase = PurchaseEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        supplier: _supplier!,
        status: status,
        createdAt: _orderDate,
        eta: _orderDate.add(const Duration(days: 7)),
        warehouse: _warehouse!,
        payments: paymentEntities,
        items: _items.map((item) {
          return PurchaseLineEntity(
            id: UniqueKey().toString(),
            name: item.name,
            sku: item.sku,
            scannedCodeGroups: item.scannedCodeGroups, 
            unitPrice: item.unitPrice,
            discountType: DiscountType.values.byName(item.discountType.name),
            discountValue: item.discountValue,
            vatRate: item.vatRate,
          );
        }).toList(),
      );

      await _createPurchase(organizationId: organizationId, purchase: newPurchase);

      _snack(approve ? 'Bon d’achat validé !' : 'Brouillon enregistré.');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _snack('Erreur lors de la sauvegarde: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  Future<void> _showAddPaymentDialog() async {
    final amountController = TextEditingController();
    String? selectedMethod = _paymentMethods.first;
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if ((double.tryParse(v) ?? 0) <= 0) return 'Montant invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Moyen de paiement',
                    border: OutlineInputBorder(),
                  ),
                  items: _paymentMethods.map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
                  onChanged: (v) => selectedMethod = v,
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
                  Navigator.pop(context, PaymentViewModel(
                    amount: double.parse(amountController.text),
                    method: selectedMethod!,
                  ));
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

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
      items: _warehouses,
      icon: Icons.home_work_outlined,
      onSelected: (selected) {
        setState(() {
          _warehouse = selected;
        });
        Navigator.pop(context);
      },
    );
  }
  
  void _showSupplierPicker() {
    _showStyledPicker(
      context: context,
      title: 'Sélectionner un fournisseur',
      items: _suppliers,
      icon: Icons.store_mall_directory_outlined,
      onSelected: (selected) {
        setState(() {
          _supplier = selected;
        });
        Navigator.pop(context);
      },
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

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }
  
  void _onNext() {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0 && (_supplier == null || _warehouse == null)) {
      _snack('Veuillez sélectionner un fournisseur et un entrepôt.', isError: true);
      return;
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
            child: PageView(
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
              supplier: _supplier,
              onSupplierTap: _showSupplierPicker,
              warehouse: _warehouse,
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

void _showStyledPicker({
  required BuildContext context,
  required String title,
  required List<String> items,
  required IconData icon,
  required ValueChanged<String> onSelected,
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
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          String searchQuery = '';
          final filteredItems = items
              .where((item) =>
                  item.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          final theme = Theme.of(context);

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
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
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(153)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary.withAlpha(25),
                              child: Icon(icon, size: 20),
                            ),
                            title: Text(item, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            onTap: () => onSelected(item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}