// lib/features/purchases/domain/usecases/get_all_purchases.dart

import '../entities/purchase_entity.dart';
import '../repositories/purchase_repository.dart';

class GetAllPurchases {
  final PurchaseRepository repository;

  GetAllPurchases(this.repository);

  Stream<List<PurchaseEntity>> call(String organizationId) {
    return repository.getAllPurchases(organizationId);
  }
}