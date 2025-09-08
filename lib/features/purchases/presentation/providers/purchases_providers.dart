// lib/features/purchases/presentation/providers/purchases_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/usecases/get_all_purchases.dart';
import '../../domain/usecases/get_purchase_details.dart';
import '../../../../core/providers/auth_providers.dart';

/// Provider for the purchases repository
final purchaseRepositoryProvider = Provider<PurchaseRepositoryImpl>((ref) {
  final remoteDataSource =
      PurchaseRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  return PurchaseRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Stream of all purchases for the current organization
final purchasesStreamProvider = StreamProvider<List<PurchaseEntity>>((ref) {
  final organizationId = ref.watch(organizationIdProvider).value;
  final repository = ref.watch(purchaseRepositoryProvider);

  if (organizationId == null) {
    return Stream.value([]);
  }

  final getAllPurchases = GetAllPurchases(repository);
  return getAllPurchases(organizationId);
});

/// Details of a single purchase by ID
final purchaseDetailProvider =
    FutureProvider.family<PurchaseEntity?, String>((ref, purchaseId) async {
  final organizationId = ref.watch(organizationIdProvider).value;
  if (organizationId == null) return null;

  final repository = ref.watch(purchaseRepositoryProvider);
  final getPurchaseDetails = GetPurchaseDetails(repository);
  return getPurchaseDetails(
      organizationId: organizationId, purchaseId: purchaseId);
});
