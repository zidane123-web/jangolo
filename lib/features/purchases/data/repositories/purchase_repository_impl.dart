// lib/features/purchases/data/repositories/purchase_repository_impl.dart

import '../../domain/entities/purchase_entity.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/remote_datasource.dart';
import '../models/purchase_model.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource remoteDataSource;

  PurchaseRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<PurchaseEntity>> getAllPurchases(String organizationId) {
    final purchaseModelsStream = remoteDataSource.getAllPurchases(organizationId);
    return purchaseModelsStream.map((models) {
      return models.map((model) => model as PurchaseEntity).toList();
    });
  }

  // ➜ Implémentation de la méthode createPurchase
  @override
  Future<void> createPurchase({
    required String organizationId,
    required PurchaseEntity purchase,
  }) {
    // On convertit notre Entité en Modèle avant de l'envoyer au DataSource
    final purchaseModel = PurchaseModel.fromEntity(purchase);
    return remoteDataSource.createPurchase(organizationId, purchaseModel);
  }

  @override
  Future<void> deletePurchase({
    required String organizationId,
    required String purchaseId,
  }) {
    // TODO: Implémenter la logique pour supprimer un achat
    throw UnimplementedError();
  }

  @override
  Future<PurchaseEntity?> getPurchaseDetails({
    required String organizationId,
    required String purchaseId,
  }) async {
    final (purchaseModel, itemModels) =
        await remoteDataSource.getPurchaseDetails(organizationId, purchaseId);

    if (purchaseModel == null) {
      return null;
    }

    return PurchaseEntity(
      id: purchaseModel.id,
      supplier: purchaseModel.supplier,
      status: purchaseModel.status,
      createdAt: purchaseModel.createdAt,
      eta: purchaseModel.eta,
      warehouse: purchaseModel.warehouse,
      items: itemModels,
      payments: purchaseModel.payments,
      createdByUserId: purchaseModel.createdByUserId,
      createdByName: purchaseModel.createdByName,
      reference: purchaseModel.reference,
      paymentTerms: purchaseModel.paymentTerms,
      notes: purchaseModel.notes,
      globalDiscount: purchaseModel.globalDiscount,
      shippingFees: purchaseModel.shippingFees,
      otherFees: purchaseModel.otherFees,
    );
  }

  @override
  Future<void> updatePurchase({
    required String organizationId,
    required PurchaseEntity purchase,
  }) {
    // TODO: Implémenter la logique pour mettre à jour un achat
    throw UnimplementedError();
  }
}