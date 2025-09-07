import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/usecases/create_purchase.dart';
import '../../../settings/data/datasources/settings_remote_datasource.dart';
import '../../../settings/data/repositories/settings_repository_impl.dart';
import '../../../settings/domain/entities/management_entities.dart';
import '../../../settings/domain/usecases/add_supplier.dart';
import '../../../settings/domain/usecases/add_warehouse.dart';
import '../../../settings/domain/usecases/get_management_data.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_line_entity.dart';
import '../models/payment_view_model.dart';
import '../models/reception_status_choice.dart';
import '../screens/purchase_line_edit_screen.dart' show LineItem;

/// Bundles initial data needed to create a purchase.
class InitialPurchaseData {
  final List<Supplier> suppliers;
  final List<Warehouse> warehouses;
  final List<PaymentMethod> paymentMethods;

  InitialPurchaseData({
    required this.suppliers,
    required this.warehouses,
    required this.paymentMethods,
  });
}

/// Handles business logic for the Create Purchase screen.
class CreatePurchaseController {
  late final CreatePurchase _createPurchase;
  late final GetSuppliers _getSuppliers;
  late final GetWarehouses _getWarehouses;
  late final GetPaymentMethods _getPaymentMethods;
  late final AddSupplier _addSupplier;
  late final AddWarehouse _addWarehouse;

  CreatePurchaseController() {
    final firestore = FirebaseFirestore.instance;
    final purchaseRemoteDataSource = PurchaseRemoteDataSourceImpl(firestore: firestore);
    final purchaseRepository = PurchaseRepositoryImpl(remoteDataSource: purchaseRemoteDataSource);
    _createPurchase = CreatePurchase(purchaseRepository);

    final settingsRemoteDataSource = SettingsRemoteDataSourceImpl(firestore: firestore);
    final settingsRepository = SettingsRepositoryImpl(remoteDataSource: settingsRemoteDataSource);
    _getSuppliers = GetSuppliers(settingsRepository);
    _getWarehouses = GetWarehouses(settingsRepository);
    _getPaymentMethods = GetPaymentMethods(settingsRepository);
    _addSupplier = AddSupplier(settingsRepository);
    _addWarehouse = AddWarehouse(settingsRepository);
  }

  Future<String> _getOrganizationId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non authentifié.');
    final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
    final organizationId = userDoc.data()?['organizationId'] as String?;
    if (organizationId == null) throw Exception('Organisation non trouvée.');
    return organizationId;
  }

  /// Loads suppliers, warehouses and payment methods for the user's organisation.
  Future<InitialPurchaseData> loadInitialData() async {
    final organizationId = await _getOrganizationId();
    final results = await Future.wait([
      _getSuppliers(organizationId),
      _getWarehouses(organizationId),
      _getPaymentMethods(organizationId),
    ]);
    return InitialPurchaseData(
      suppliers: results[0] as List<Supplier>,
      warehouses: results[1] as List<Warehouse>,
      paymentMethods: results[2] as List<PaymentMethod>,
    );
  }

  /// Persists a purchase to Firestore using the provided form data.
  Future<void> savePurchase({
    required Supplier supplier,
    required Warehouse warehouse,
    required DateTime orderDate,
    required List<LineItem> items,
    required List<PaymentViewModel> payments,
    required List<PaymentMethod> paymentMethods,
    required ReceptionStatusChoice receptionChoice,
    required bool approve,
  }) async {
    final organizationId = await _getOrganizationId();

    final grandTotal =
        items.fold<double>(0.0, (total, item) => total + item.lineTotal.toDouble());
    final totalPaid = payments.fold(0.0, (total, p) => total + p.amount);

    final List<PaymentEntity> paymentEntities = [];
    for (var i = 0; i < payments.length; i++) {
      final p = payments[i];
      final method = paymentMethods.firstWhere(
        (m) => m.name == p.method,
        orElse: () => PaymentMethod(id: '', name: p.method, type: ''),
      );
      paymentEntities.add(
        PaymentEntity(
          id: 'pay-${DateTime.now().microsecondsSinceEpoch}-$i',
          amount: p.amount,
          date: DateTime.now(),
          paymentMethod: method,
        ),
      );
    }

    final bool isFullyPaid =
        (grandTotal > 0) && (grandTotal - totalPaid).abs() < 0.01;
    PurchaseStatus status;

    if (!approve) {
      status = PurchaseStatus.draft;
    } else if (receptionChoice == ReceptionStatusChoice.alreadyReceived && isFullyPaid) {
      status = PurchaseStatus.paid;
    } else if (receptionChoice == ReceptionStatusChoice.alreadyReceived) {
      status = PurchaseStatus.received;
    } else {
      status = PurchaseStatus.approved;
    }

    final newPurchase = PurchaseEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      supplier: supplier,
      status: status,
      createdAt: orderDate,
      eta: orderDate.add(const Duration(days: 7)),
      warehouse: warehouse,
      payments: paymentEntities,
      items: items.asMap().entries.map((entry) {
        final item = entry.value;
        final index = entry.key;
        return PurchaseLineEntity(
          id: 'line-${DateTime.now().microsecondsSinceEpoch}-$index',
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

    await _createPurchase(
      organizationId: organizationId,
      purchase: newPurchase,
    );
  }

  /// Adds a new supplier to the organisation.
  Future<Supplier> addSupplier({required String name, String? phone}) async {
    final organizationId = await _getOrganizationId();
    return _addSupplier(
      organizationId: organizationId,
      name: name,
      phone: phone,
    );
  }

  /// Adds a new warehouse to the organisation.
  Future<Warehouse> addWarehouse({required String name, String? address}) async {
    final organizationId = await _getOrganizationId();
    return _addWarehouse(
      organizationId: organizationId,
      name: name,
      address: address,
    );
  }
}

