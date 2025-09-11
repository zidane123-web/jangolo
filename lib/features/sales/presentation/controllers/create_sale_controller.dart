// lib/features/sales/presentation/controllers/create_sale_controller.dart

import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../domain/usecases/create_sale.dart';

/// Simple controller handling creation of a sale.
class CreateSaleController {
  final CreateSale _createSale;
  CreateSaleController(SalesRepository repository)
      : _createSale = CreateSale(repository);

  Future<void> saveSale({
    required String organizationId,
    required SaleEntity sale,
  }) {
    return _createSale(organizationId: organizationId, sale: sale);
  }
}
