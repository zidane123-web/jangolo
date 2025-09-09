import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/management_entities.dart';
import '../../domain/usecases/get_management_data.dart';
import '../../../../core/providers/auth_providers.dart';

/// Provider that exposes a [Future] list of [Warehouse] for the current organization.
final warehousesProvider = FutureProvider<List<Warehouse>>((ref) async {
  final organizationId = ref.watch(organizationIdProvider).value;
  if (organizationId == null) {
    return [];
  }
  final remoteDataSource =
      SettingsRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  final repository = SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
  final getWarehouses = GetWarehouses(repository);
  return getWarehouses(organizationId);
});

/// Provider that exposes a [Future] list of [PaymentMethod] for the current organization.
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final organizationId = ref.watch(organizationIdProvider).value;
  if (organizationId == null) {
    return [];
  }
  final remoteDataSource =
      SettingsRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  final repository = SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
  final getPaymentMethods = GetPaymentMethods(repository);
  return getPaymentMethods(organizationId);
});
