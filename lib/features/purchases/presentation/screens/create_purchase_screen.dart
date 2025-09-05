// lib/features/purchases/presentation/screens/create_purchase_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORTS POUR L'ARCHITECTURE ---
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_line_entity.dart';
import '../../domain/usecases/create_purchase.dart';

// --- IMPORTS POUR L'UI ---
import 'purchase_line_edit_screen.dart';
import '../widgets/create_purchase/supplier_info_form.dart';
import '../widgets/create_purchase/line_items_section.dart';
import '../widgets/create_purchase/purchase_summary_card.dart';
// ✅ --- NOUVEL IMPORT ---
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
  // ✅ Passe à 4 étapes
  int _currentStep = 0;
  
  // --- ETAT ETAPE 1 ---
  String? _supplier;
  DateTime _orderDate = DateTime.now();
  String? _warehouse = 'Entrepôt Cotonou';
  
  // --- ETAT ETAPE 2 ---
  final List<LineItem> _items = [];
  
  // ✅ --- NOUVEL ETAT POUR L'ETAPE 3 ---
  ReceptionStatusChoice _receptionChoice = ReceptionStatusChoice.toReceive;
  PaymentStatusChoice _paymentChoice = PaymentStatusChoice.notPaid;
  final _partialAmountController = TextEditingController();
  String? _paymentMethod;
  final _paymentMethods = const ['Caisse', 'Banque', 'Mobile Money'];
  // --- FIN NOUVEL ETAT ---

  final _suppliers = const [
    'TechDistrib SARL', 'Global Imports SA', 'Phone Accessoires Plus',
    'Innovations Mobiles', 'Électro Fourniture Express'
  ];
  final _warehouses = const [
    'Entrepôt Cotonou', 'Magasin Porto-Novo', 'Dépôt Parakou'
  ];

  final String _currency = 'F';
  bool _isSaving = false;

  late final CreatePurchase _createPurchase;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final remoteDataSource =
        PurchaseRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository = PurchaseRepositoryImpl(remoteDataSource: remoteDataSource);
    _createPurchase = CreatePurchase(repository);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _partialAmountController.dispose();
    super.dispose();
  }

  Future<void> _save({required bool approve}) async {
    // La validation se fait maintenant à l'étape 3
    if (_paymentChoice != PaymentStatusChoice.notPaid && _paymentMethod == null) {
      _snack('Veuillez sélectionner un compte de paiement.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté.");
      final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
      final organizationId = userDoc.data()?['organizationId'] as String?;
      if (organizationId == null) throw Exception("Organisation non trouvée.");

      final grandTotal = _items.fold<double>(0.0, (total, item) => total + item.lineTotal.toDouble());
      final List<PaymentEntity> payments = [];
      
      if (_paymentChoice != PaymentStatusChoice.notPaid) {
        double amountPaid = 0;
        if (_paymentChoice == PaymentStatusChoice.fullyPaid) {
          amountPaid = grandTotal;
        } else { // partiallyPaid
          amountPaid = double.tryParse(_partialAmountController.text) ?? 0.0;
        }

        if (amountPaid > 0) {
           payments.add(PaymentEntity(
            id: UniqueKey().toString(),
            amount: amountPaid,
            date: DateTime.now(),
            paymentMethod: _paymentMethod!,
            treasuryAccountId: _paymentMethod!, // Simplification pour l'exemple
          ));
        }
      }

      final bool isFullyPaid = (grandTotal - payments.fold(0.0, (sum, p) => sum + p.amount)) < 0.01;
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
        payments: payments,
        items: _items.map((item) {
          final domainDiscountType = DiscountType.values.byName(item.discountType.name);
          return PurchaseLineEntity(
            id: UniqueKey().toString(),
            name: item.name,
            sku: item.sku,
            scannedCodeGroups: item.scannedCodeGroups, 
            unitPrice: item.unitPrice,
            discountType: domainDiscountType,
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
  
  // --- Les autres méthodes (snack, pickers, etc.) restent inchangées ---
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
  
  void _showPaymentMethodPicker() {
    _showStyledPicker(
      context: context,
      title: 'Sélectionner un compte',
      items: _paymentMethods,
      icon: Icons.account_balance_wallet_outlined,
      onSelected: (selected) {
        setState(() => _paymentMethod = selected);
        Navigator.pop(context);
      },
    );
  }

  void _showWarehousePicker() {
    _showStyledPicker(
      context: context,
      title: 'Sélectionner un entrepôt',
      items: _warehouses,
      icon: Icons.home_work_outlined,
      onSelected: (selected) {
        setState(() => _warehouse = selected);
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
        setState(() => _supplier = selected);
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
    
    if (_currentStep == 0) {
      if (_supplier == null || _warehouse == null) {
        _snack('Veuillez sélectionner un fournisseur et un entrepôt.', isError: true);
        return;
      }
    }
    if (_currentStep == 1) {
      if (_items.isEmpty) {
        _snack('Veuillez ajouter au moins un article.', isError: true);
        return;
      }
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          // ✅ Titre mis à jour pour 4 étapes
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
            children: [
              _buildStep1(),
              _buildStep2(),
              // ✅ AJOUT de la nouvelle étape 3
              _buildStep3(),
              // ✅ Le résumé devient l'étape 4
              _buildStep4(),
            ],
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
            // ✅ Le formulaire n'a plus besoin des paramètres de réception
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
                OutlinedButton(
                  onPressed: _onBack,
                  child: const Text('Retour'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _onNext,
                  child: const Text('Suivant'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ --- NOUVELLE METHODE POUR L'ETAPE 3 ---
  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: PaymentAndReceptionStep(
            paymentStatus: _paymentChoice,
            onPaymentStatusChanged: (choice) => setState(() => _paymentChoice = choice),
            partialAmountController: _partialAmountController,
            paymentMethod: _paymentMethod,
            onPaymentMethodTap: _showPaymentMethodPicker,
            receptionStatus: _receptionChoice,
            onReceptionStatusChanged: (choice) => setState(() => _receptionChoice = choice),
            currency: _currency,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _onBack,
                child: const Text('Retour'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _onNext,
                child: const Text('Suivant'),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ✅ L'ancien `_buildStep3` devient `_buildStep4`
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          PurchaseSummaryCard(
            grandTotal: _items.fold<double>(
                0.0, (total, item) => total + item.lineTotal.toDouble()),
            currency: _currency,
          ),
          const SizedBox(height: 32),
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onBack,
                    child: const Text('Retour'),
                  ),
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

// La méthode _showStyledPicker reste inchangée
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