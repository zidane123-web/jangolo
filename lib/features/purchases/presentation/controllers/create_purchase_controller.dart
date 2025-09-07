import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jangolo/features/inventory/data/models/article_model.dart';

import '../../data/datasources/remote_datasource.dart';
import '../../data/models/purchase_line_model.dart';
import '../../data/models/purchase_model.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_line_entity.dart';
import '../../domain/usecases/create_purchase.dart';
import '../models/payment_view_model.dart';
import '../models/reception_status_choice.dart';
import '../screens/purchase_line_edit_screen.dart' show LineItem;
import '../../../settings/data/datasources/settings_remote_datasource.dart';
import '../../../settings/data/repositories/settings_repository_impl.dart';
import '../../../settings/domain/entities/management_entities.dart';
import '../../../settings/domain/usecases/add_supplier.dart';
import '../../../settings/domain/usecases/add_warehouse.dart';
import '../../../settings/domain/usecases/get_management_data.dart';

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

class CreatePurchaseController {
  late final FirebaseFirestore _firestore; // pour les transactions
  late final CreatePurchase _createPurchase;
  late final GetSuppliers _getSuppliers;
  late final GetWarehouses _getWarehouses;
  late final GetPaymentMethods _getPaymentMethods;
  late final AddSupplier _addSupplier;
  late final AddWarehouse _addWarehouse;
  CreatePurchaseController() {
    _firestore = FirebaseFirestore.instance;
    final purchaseRemoteDataSource =
        PurchaseRemoteDataSourceImpl(firestore: _firestore);
    final purchaseRepository =
        PurchaseRepositoryImpl(remoteDataSource: purchaseRemoteDataSource);
    _createPurchase = CreatePurchase(purchaseRepository);

    final settingsRemoteDataSource =
        SettingsRemoteDataSourceImpl(firestore: _firestore);
    final settingsRepository =
        SettingsRepositoryImpl(remoteDataSource: settingsRemoteDataSource);
    _getSuppliers = GetSuppliers(settingsRepository);
    _getWarehouses = GetWarehouses(settingsRepository);
    _getPaymentMethods = GetPaymentMethods(settingsRepository);
    _addSupplier = AddSupplier(settingsRepository);
    _addWarehouse = AddWarehouse(settingsRepository);
  }

  Future<String> _getOrganizationId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non authentifié.');
    final userDoc =
        await _firestore.collection('utilisateurs').doc(user.uid).get();
    final organizationId = userDoc.data()?['organizationId'] as String?;
    if (organizationId == null) throw Exception('Organisation non trouvée.');
    return organizationId;
  }

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

  Future<void> savePurchase({
    required Supplier supplier,
    required Warehouse warehouse,
    required DateTime orderDate,
    required List<LineItem> items,
    required List<PaymentViewModel> payments,
    required List<PaymentMethod> paymentMethods,
    required ReceptionStatusChoice receptionChoice,
    required double shippingFees,
    required bool approve,
  }) async {
    final organizationId = await _getOrganizationId();
    final isReceived = receptionChoice == ReceptionStatusChoice.alreadyReceived;

    final purchaseEntity = _buildPurchaseEntity(
      supplier: supplier,
      warehouse: warehouse,
      orderDate: orderDate,
      items: items,
      payments: payments,
      paymentMethods: paymentMethods,
      receptionChoice: receptionChoice,
      shippingFees: shippingFees,
      approve: approve,
    );

    await _firestore.runTransaction((transaction) async {
      final purchaseRef = _firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('purchases')
          .doc(purchaseEntity.id);

      final purchaseModel = PurchaseModel.fromEntity(purchaseEntity);
      transaction.set(purchaseRef, purchaseModel.toJson());

      for (final item in purchaseEntity.items) {
        final itemRef = purchaseRef.collection('items').doc(item.id);
        final itemModel = PurchaseLineModel.fromEntity(item);
        transaction.set(itemRef, itemModel.toJson());
      }

      if (isReceived && approve) {
        for (final lineItem in items) {
          if (lineItem.sku == null || lineItem.sku!.isEmpty) continue;

          final articleRef = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('inventory')
              .doc(lineItem.sku!);

          final articleSnapshot = await transaction.get(articleRef);
          if (!articleSnapshot.exists) {
            throw Exception('Article avec SKU ${lineItem.sku} non trouvé.');
          }
          final oldArticle = ArticleModel.fromSnapshot(articleSnapshot);

          final oldQty = oldArticle.totalQuantity;
          final oldCost = oldArticle.buyPrice;
          final newQty = lineItem.qty;
          final newPrice = lineItem.unitPrice;

          final newTotalQty = oldQty + newQty;
          final newWeightedCost =
              ((oldQty * oldCost) + (newQty * newPrice)) / newTotalQty;

          transaction.update(articleRef, {
            'totalQuantity': newTotalQty,
            'buyPrice': newWeightedCost,
          });
        }
      }
    });
  }

  PurchaseEntity _buildPurchaseEntity({
    required Supplier supplier,
    required Warehouse warehouse,
    required DateTime orderDate,
    required List<LineItem> items,
    required List<PaymentViewModel> payments,
    required List<PaymentMethod> paymentMethods,
    required ReceptionStatusChoice receptionChoice,
    required double shippingFees,
    required bool approve,
  }) {
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
    } else if (receptionChoice == ReceptionStatusChoice.alreadyReceived &&
        isFullyPaid) {
      status = PurchaseStatus.paid;
    } else if (receptionChoice == ReceptionStatusChoice.alreadyReceived) {
      status = PurchaseStatus.received;
    } else {
      status = PurchaseStatus.approved;
    }

    return PurchaseEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      supplier: supplier,
      status: status,
      createdAt: orderDate,
      eta: orderDate.add(const Duration(days: 7)),
      warehouse: warehouse,
      payments: paymentEntities,
      shippingFees: shippingFees,
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
  }

  Future<Supplier> addSupplier({required String name, String? phone}) async {
    final organizationId = await _getOrganizationId();
    return _addSupplier(
      organizationId: organizationId,
      name: name,
      phone: phone,
    );
  }

  Future<Warehouse> addWarehouse({required String name, String? address}) async {
    final organizationId = await _getOrganizationId();
    return _addWarehouse(
      organizationId: organizationId,
      name: name,
      address: address,
    );
  }
}

