// lib/features/sales/domain/repositories/sales_repository.dart

import '../entities/sale_entity.dart';

abstract class SalesRepository {
  /// Stream of all sales for a given organisation.
  Stream<List<SaleEntity>> getAllSales(String organizationId);

  /// Creates a new sale in the remote data source.
  Future<void> createSale({
    required String organizationId,
    required SaleEntity sale,
  });

  /// Updates an existing sale.
  Future<void> updateSale({
    required String organizationId,
    required SaleEntity sale,
  });

  /// Retrieves details for a specific sale.
  Future<SaleEntity?> getSaleDetails({
    required String organizationId,
    required String saleId,
  });
}
