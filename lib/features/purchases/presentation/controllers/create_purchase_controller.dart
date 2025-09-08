import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jangolo/features/inventory/data/models/article_model.dart';
import '../../../settings/data/datasources/settings_remote_datasource.dart';
import '../../../settings/data/repositories/settings_repository_impl.dart';
import '../../../settings/domain/entities/management_entities.dart';
import '../../../settings/domain/usecases/add_supplier.dart';
import '../../../settings/domain/usecases/add_warehouse.dart';
import '../../../settings/domain/usecases/get_management_data.dart';
import '../../data/models/purchase_line_model.dart';
import '../../data/models/purchase_model.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_line_entity.dart';
import '../models/payment_view_model.dart';
import '../models/reception_status_choice.dart';
import '../screens/purchase_line_edit_screen.dart' show LineItem;
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';
import '../../../inventory/data/repositories/inventory_repository_impl.dart';
import '../../../inventory/domain/entities/movement_entity.dart';
import '../../../inventory/domain/usecases/add_movement.dart';

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
  late final FirebaseFirestore _firestore;
  late final GetSuppliers _getSuppliers;
  late final GetWarehouses _getWarehouses;
  late final GetPaymentMethods _getPaymentMethods;
  late final AddSupplier _addSupplier;
  late final AddWarehouse _addWarehouse;
  late final InventoryRepositoryImpl _inventoryRepository;
  late final AddMovement _addMovement;

  CreatePurchaseController() {
    _firestore = FirebaseFirestore.instance;

    final settingsRemoteDataSource =
        SettingsRemoteDataSourceImpl(firestore: _firestore);
    final settingsRepository =
        SettingsRepositoryImpl(remoteDataSource: settingsRemoteDataSource);
    _getSuppliers = GetSuppliers(settingsRepository);
    _getWarehouses = GetWarehouses(settingsRepository);
    _getPaymentMethods = GetPaymentMethods(settingsRepository);
    _addSupplier = AddSupplier(settingsRepository);
    _addWarehouse = AddWarehouse(settingsRepository);

    final inventoryRemoteDataSource =
        InventoryRemoteDataSourceImpl(firestore: _firestore);
    _inventoryRepository =
        InventoryRepositoryImpl(remoteDataSource: inventoryRemoteDataSource);
    _addMovement = AddMovement(_inventoryRepository);
  }

  Future<InitialPurchaseData> loadInitialData(String organizationId) async {
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
    required String organizationId,
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
    final isReceived =
        receptionChoice == ReceptionStatusChoice.alreadyReceived;

    // Sous-total utilisé pour répartir les frais de transport
    final purchaseSubtotal = items.fold<double>(
        0.0, (sum, item) => sum + item.lineSubtotal.toDouble());

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
      // ✅ --- ÉTAPE 1: LECTURES D'ABORD ---
      final List<DocumentSnapshot> articleSnapshots = [];
      if (isReceived && approve) {
        for (final lineItem in items) {
          if (lineItem.sku == null || lineItem.sku!.isEmpty) continue;

          final articleRef = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('inventory')
              .doc(lineItem.sku!);

          // On lit tous les articles nécessaires D'ABORD.
          final articleSnapshot = await transaction.get(articleRef);
          if (!articleSnapshot.exists) {
            throw Exception('Article avec SKU ${lineItem.sku} non trouvé.');
          }
          articleSnapshots.add(articleSnapshot);
        }
      }

      // ✅ --- ÉTAPE 2: ÉCRITURES ENSUITE ---

      // 2a. Écriture du bon de commande
      final purchaseRef = _firestore
          .collection('organisations')
          .doc(organizationId)
          .collection('purchases')
          .doc(purchaseEntity.id);

      final purchaseModel = PurchaseModel.fromEntity(purchaseEntity);
      transaction.set(purchaseRef, purchaseModel.toJson());

      // 2b. Écriture des lignes d'articles
      for (final item in purchaseEntity.items) {
        final itemRef = purchaseRef.collection('items').doc(item.id);
        final itemModel = PurchaseLineModel.fromEntity(item);
        transaction.set(itemRef, itemModel.toJson());
      }

      // 2c. Mise à jour du stock (si nécessaire)
      if (isReceived && approve) {
        for (int i = 0; i < items.length; i++) {
          final lineItem = items[i];
          if (lineItem.sku == null || lineItem.sku!.isEmpty) continue;

          final articleRef = _firestore
              .collection('organisations')
              .doc(organizationId)
              .collection('inventory')
              .doc(lineItem.sku!);

          // On utilise le snapshot déjà lu
          final oldArticle = ArticleModel.fromSnapshot(articleSnapshots[i]);

          final oldQty = oldArticle.totalQuantity;
          final oldCost = oldArticle.buyPrice;
          final newQty = lineItem.qty;

          // Répartition des frais de transport pour cette ligne
          final proportion = purchaseSubtotal > 0
              ? (lineItem.lineSubtotal / purchaseSubtotal)
              : 0;
          final shippingShareForLine = shippingFees * proportion;
          final shippingPerUnit = newQty > 0
              ? (shippingShareForLine / newQty)
              : 0;
          final landedCost = lineItem.unitPrice + shippingPerUnit;

          final newPrice = landedCost; // coût d'acquisition

          final newTotalQty = oldQty + newQty;
          // On évite la division par zéro si le stock total devient nul
          final newWeightedCost = newTotalQty > 0
              ? ((oldQty * oldCost) + (newQty * newPrice)) / newTotalQty
              : 0;

          transaction.update(articleRef, {
            'totalQuantity': newTotalQty,
            'buyPrice': newWeightedCost,
          });

          final movementId = articleRef.collection('movements').doc().id;
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          final movement = MovementEntity(
            id: movementId,
            type: MovementType.inn,
            qty: newQty.toInt(), // ✅ CORRECTION APPLIQUÉE ICI
            date: DateTime.now(),
            reason: 'Réception Achat #${purchaseEntity.id}',
            userId: userId,
            sourceDocument: purchaseEntity.id,
          );
          await _addMovement(organizationId, lineItem.sku!, movement);
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
    final grandTotal = items.fold<double>(
        0.0, (total, item) => total + item.lineTotal.toDouble());
    final totalPaid =
        payments.fold(0.0, (total, p) => total + p.amount);

    // Sous-total avant frais de transport, utilisé pour la répartition
    final purchaseSubtotal = items.fold<double>(
        0.0, (sum, item) => sum + item.lineSubtotal.toDouble());

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
        final proportion = purchaseSubtotal > 0
            ? (item.lineSubtotal / purchaseSubtotal)
            : 0;
        final shippingShareForLine = shippingFees * proportion;
        return PurchaseLineEntity(
          id: 'line-${DateTime.now().microsecondsSinceEpoch}-$index',
          name: item.name,
          sku: item.sku,
          scannedCodeGroups: item.scannedCodeGroups,
          unitPrice: item.unitPrice,
          discountType: DiscountType.values.byName(item.discountType.name),
          discountValue: item.discountValue,
          vatRate: item.vatRate,
          allocatedShipping: shippingShareForLine,
        );
      }).toList(),
    );
  }

  Future<Supplier> addSupplier({
    required String organizationId,
    required String name,
    String? phone,
  }) {
    return _addSupplier(
      organizationId: organizationId,
      name: name,
      phone: phone,
    );
  }

  Future<Warehouse> addWarehouse({
    required String organizationId,
    required String name,
    String? address,
  }) {
    return _addWarehouse(
      organizationId: organizationId,
      name: name,
      address: address,
    );
  }
}