// lib/features/sales/domain/usecases/create_sale.dart

import '../entities/sale_entity.dart';
import '../repositories/sales_repository.dart';

class CreateSale {
  final SalesRepository repository;
  CreateSale(this.repository);

  Future<void> call({
    required String organizationId,
    required SaleEntity sale,
  }) {
    return repository.createSale(
      organizationId: organizationId,
      sale: sale,
    );
  }
}
