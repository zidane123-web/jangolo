import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../settings/domain/entities/management_entities.dart';
import '../controllers/create_purchase_controller.dart';
import '../models/payment_view_model.dart';
import '../models/reception_status_choice.dart';
import 'purchase_line_edit_screen.dart' show LineItem;
import '../widgets/create_purchase/add_payment_dialog.dart';
import '../widgets/create_purchase/confirm_exit.dart';
import '../widgets/create_purchase/line_items_step.dart';
import '../widgets/create_purchase/payment_and_reception_step_wrapper.dart';
import '../widgets/create_purchase/supplier_and_warehouse_step.dart';
import '../widgets/create_purchase/summary_step.dart';
import '../widgets/create_purchase/warehouse_supplier_picker.dart';

class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  late final PageController _pageController;
  int _currentStep = 0;

  bool _isLoading = true;
  String? _loadingError;

  Supplier? _supplier; Warehouse? _warehouse; DateTime _orderDate = DateTime.now();
  final _items = <LineItem>[]; ReceptionStatusChoice _receptionChoice = ReceptionStatusChoice.toReceive;
  final _payments = <PaymentViewModel>[];
  List<Supplier> _suppliers = [], _warehouses = []; List<PaymentMethod> _paymentMethods = [];
  final String _currency = 'F'; bool _isSaving = false;

  late final CreatePurchaseController _controller;
  late final DateTime _initialOrderDate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initialOrderDate = _orderDate;
    _controller = CreatePurchaseController();
    _controller.loadInitialData().then((data) {
      if (!mounted) return;
      setState(() {
        _suppliers = data.suppliers;
        _warehouses = data.warehouses;
        _paymentMethods = data.paymentMethods;
        if (_warehouses.isNotEmpty) _warehouse = _warehouses.first;
        _isLoading = false;
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _loadingError = "Erreur de chargement: ${e.toString()}";
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isFormDirty => _supplier != null || _warehouse != null || _items.isNotEmpty || _payments.isNotEmpty || _receptionChoice != ReceptionStatusChoice.toReceive || _orderDate != _initialOrderDate;

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : null),
    );
  }

  void _onNext() {
    if (_currentStep == 0 && !_step1FormKey.currentState!.validate()) return;
    if (_currentStep == 1 && _items.isEmpty) {
      _snack('Veuillez ajouter au moins un article.', isError: true);
      return;
    }
    if (_currentStep == 2 && _payments.isEmpty) {
      _snack('Veuillez ajouter un paiement.', isError: true);
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _onBack() { FocusScope.of(context).unfocus(); _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); }

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
        _snack(approve ? 'Bon d\'achat validé !' : 'Brouillon enregistré.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _snack('Erreur lors de la sauvegarde: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFormDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await confirmExit(context) && context.mounted) Navigator.pop(context);
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
                    ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_loadingError!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error))))
                    : PageView(controller: _pageController, physics: const NeverScrollableScrollPhysics(), onPageChanged: (p) => setState(() => _currentStep = p), children: [
                        SupplierAndWarehouseStep(
                          formKey: _step1FormKey,
                          supplier: _supplier?.name,
                          onSupplierTap: () async { final s = await pickSupplier(context: context, suppliers: _suppliers, controller: _controller, snack: _snack); if (s != null) setState(() => _supplier = s); },
                          warehouse: _warehouse?.name,
                          onWarehouseTap: () async { final w = await pickWarehouse(context: context, warehouses: _warehouses, controller: _controller, snack: _snack); if (w != null) setState(() => _warehouse = w); },
                          orderDate: _orderDate,
                          onOrderDateTap: () async { final d = await showDatePicker(context: context, initialDate: _orderDate, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => _orderDate = d); },
                          onNext: _onNext,
                        ),
                        LineItemsStep(items: _items, currency: _currency, onBack: _onBack, onNext: _onNext, refresh: (fn) => setState(fn)),
                        PaymentAndReceptionStepWrapper(
                          grandTotal: _items.fold<double>(0.0, (t, i) => t + i.lineTotal.toDouble()),
                          currency: _currency,
                          payments: _payments,
                          onAddPayment: () async { final gt = _items.fold<double>(0.0, (t, i) => t + i.lineTotal.toDouble()); final res = await showAddPaymentDialog(context: context, currency: _currency, grandTotal: gt, existingPayments: _payments, paymentMethods: _paymentMethods); if (res != null) setState(() => _payments.add(res)); },
                          onRemovePayment: (i) => setState(() => _payments.removeAt(i)),
                          receptionStatus: _receptionChoice,
                          onReceptionStatusChanged: (ReceptionStatusChoice c) => setState(() => _receptionChoice = c),
                          onBack: _onBack,
                          onNext: _onNext,
                        ),
                        SummaryStep(items: _items, currency: _currency, isSaving: _isSaving, onBack: _onBack, onSaveDraft: () => _save(approve: false), onValidate: () => _save(approve: true)),
                      ]),
          ),
        ),
      ),
    );
  }
}
