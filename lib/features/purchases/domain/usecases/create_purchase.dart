// lib/features/purchases/domain/usecases/create_purchase.dart

import '../entities/purchase_entity.dart';
import '../repositories/purchase_repository.dart';

class CreatePurchase {
  final PurchaseRepository repository;

  CreatePurchase(this.repository);

  Future<void> call({
    required String organizationId,
    required PurchaseEntity purchase,
  }) {
    // Ici, on pourrait ajouter des logiques de validation complexes
    // avant d'appeler le repository.
    return repository.createPurchase(
      organizationId: organizationId,
      purchase: purchase,
    );
  }
}