// lib/features/sales/domain/usecases/get_sale_details.dart

import '../entities/sale_entity.dart';
import '../repositories/sales_repository.dart';

class GetSaleDetails {
  final SalesRepository repository;
  GetSaleDetails(this.repository);

  Future<SaleEntity?> call({
    required String organizationId,
    required String saleId,
  }) {
    return repository.getSaleDetails(
      organizationId: organizationId,
      saleId: saleId,
    );
  }
}
