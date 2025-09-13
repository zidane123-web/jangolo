// lib/features/sales/data/repositories/sales_repository_impl.dart

import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/remote_datasource.dart';
import '../models/payment_model.dart';
import '../models/sale_model.dart';

class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDataSource remoteDataSource;
  SalesRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<SaleEntity>> getAllSales(String organizationId) {
    final modelsStream = remoteDataSource.getAllSales(organizationId);
    return modelsStream.map((models) =>
        models.map((model) => model as SaleEntity).toList());
  }

  @override
  Future<void> createSale({
    required String organizationId,
    required SaleEntity sale,
  }) {
    final model = SaleModel.fromEntity(sale);
    return remoteDataSource.createSale(organizationId, model);
  }

  @override
  Future<SaleEntity?> getSaleDetails({
    required String organizationId,
    required String saleId,
  }) async {
    final (saleModel, lineModels, paymentModels) =
        await remoteDataSource.getSaleDetails(organizationId, saleId);
    if (saleModel == null) return null;
    final payments = paymentModels.map((p) => p as PaymentEntity).toList();

    return SaleEntity(
      id: saleModel.id,
      customerId: saleModel.customerId,
      customerName: saleModel.customerName,
      status: saleModel.status,
      createdAt: saleModel.createdAt,
      items: lineModels,
      payments: payments,
      globalDiscount: saleModel.globalDiscount,
      shippingFees: saleModel.shippingFees,
      otherFees: saleModel.otherFees,
      createdBy: saleModel.createdBy,
      createdByName: saleModel.createdByName,
      hasDelivery: saleModel.hasDelivery,
      grandTotal: saleModel.grandTotal,
    );
  }

  @override
  Future<void> updateSale({
    required String organizationId,
    required SaleEntity sale,
  }) {
    final model = SaleModel.fromEntity(sale);
    return remoteDataSource.updateSale(organizationId, model);
  }

  @override
  Future<void> addPayment({
    required String organizationId,
    required String saleId,
    required PaymentEntity payment,
  }) {
    PaymentModel.fromEntity(payment);
    // La logique de transaction est gérée dans SaleDetailController.
    throw UnimplementedError('Handled by SaleDetailController transaction');
  }
}