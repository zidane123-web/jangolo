// lib/features/sales/domain/usecases/get_all_sales.dart

import '../entities/sale_entity.dart';
import '../repositories/sales_repository.dart';

class GetAllSales {
  final SalesRepository repository;
  GetAllSales(this.repository);

  Stream<List<SaleEntity>> call(String organizationId) {
    return repository.getAllSales(organizationId);
  }
}
