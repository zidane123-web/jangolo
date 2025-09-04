// lib/features/purchases/domain/usecases/update_purchase.dart

import '../entities/purchase_entity.dart';
import '../repositories/purchase_repository.dart';

class UpdatePurchase {
  final PurchaseRepository repository;

  UpdatePurchase(this.repository);

  Future<void> call({
    required String organizationId,
    required PurchaseEntity purchase,
  }) {
    return repository.updatePurchase(
      organizationId: organizationId,
      purchase: purchase,
    );
  }
}