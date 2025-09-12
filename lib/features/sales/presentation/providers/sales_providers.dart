// lib/features/sales/presentation/providers/sales_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/entities/sale_entity.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/usecases/add_client.dart';
import '../../domain/usecases/get_clients.dart';
import '../../domain/usecases/get_all_sales.dart';
import '../../domain/usecases/get_sale_details.dart';
import '../controllers/create_sale_controller.dart';

/// Provider for the sales repository
final salesRepositoryProvider = Provider<SalesRepositoryImpl>((ref) {
  final remoteDataSource =
      SalesRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  return SalesRepositoryImpl(remoteDataSource: remoteDataSource);
});

// --- NEW PROVIDERS FOR CLIENTS ---

/// Provider for the client repository
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final remoteDataSource =
      SalesRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  return ClientRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Stream of all clients for the current organization
final clientsStreamProvider = StreamProvider<List<ClientEntity>>((ref) {
  final organizationId = ref.watch(organizationIdProvider).value;
  final repository = ref.watch(clientRepositoryProvider);

  if (organizationId == null) {
    return Stream.value([]);
  }
  final getClients = GetClients(repository);
  return getClients(organizationId);
});

/// Use case for adding a client
final addClientProvider = Provider<AddClient>((ref) {
  final repository = ref.watch(clientRepositoryProvider);
  return AddClient(repository);
});

// --- END NEW PROVIDERS ---

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

/// Search query for filtering sales by customer name
final salesSearchProvider = StateProvider<String>((ref) => '');

/// Optional status filter; `null` means all statuses
final salesStatusFilterProvider = StateProvider<SaleStatus?>((ref) => null);

/// Combines stream, search query and status filter to expose filtered sales
final filteredSalesProvider =
    Provider<AsyncValue<List<SaleEntity>>>((ref) {
  final salesAsync = ref.watch(salesStreamProvider);
  final query = ref.watch(salesSearchProvider);
  final status = ref.watch(salesStatusFilterProvider);

  return salesAsync.whenData((sales) {
    return sales.where((sale) {
      final matchesQuery = query.isEmpty ||
          (sale.customerName ?? '')
              .toLowerCase()
              .contains(query.toLowerCase());
      final matchesStatus = status == null || sale.status == status;
      return matchesQuery && matchesStatus;
    }).toList();
  });
});
