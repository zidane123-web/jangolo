// lib/features/purchases/domain/usecases/get_purchase_details.dart

import '../entities/purchase_entity.dart';
import '../repositories/purchase_repository.dart';

class GetPurchaseDetails {
  final PurchaseRepository repository;

  GetPurchaseDetails(this.repository);

  Future<PurchaseEntity?> call({
    required String organizationId,
    required String purchaseId,
  }) {
    return repository.getPurchaseDetails(
      organizationId: organizationId,
      purchaseId: purchaseId,
    );
  }
}