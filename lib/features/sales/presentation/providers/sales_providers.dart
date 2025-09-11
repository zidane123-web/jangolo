// lib/features/sales/presentation/providers/sales_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/usecases/get_all_sales.dart';
import '../../domain/usecases/get_sale_details.dart';
import '../controllers/create_sale_controller.dart';

/// Provider for the sales repository
final salesRepositoryProvider = Provider<SalesRepositoryImpl>((ref) {
  final remoteDataSource =
      SalesRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  return SalesRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Stream of all sales for the current organization
final salesStreamProvider = StreamProvider<List<SaleEntity>>((ref) {
  final organizationId = ref.watch(organizationIdProvider).value;
  final repository = ref.watch(salesRepositoryProvider);

  if (organizationId == null) {
    return Stream.value([]);
  }

  final getAllSales = GetAllSales(repository);
  return getAllSales(organizationId);
});

/// Details of a single sale by ID
final saleDetailProvider =
    FutureProvider.family<SaleEntity?, String>((ref, saleId) async {
  final organizationId = ref.watch(organizationIdProvider).value;
  if (organizationId == null) return null;

  final repository = ref.watch(salesRepositoryProvider);
  final getSaleDetails = GetSaleDetails(repository);
  return getSaleDetails(organizationId: organizationId, saleId: saleId);
});

/// Controller used to create a new sale
final createSaleControllerProvider = Provider<CreateSaleController>((ref) {
  final repository = ref.watch(salesRepositoryProvider);
  return CreateSaleController(repository);
});
