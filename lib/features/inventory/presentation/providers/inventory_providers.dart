import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/article_entity.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../domain/usecases/get_articles.dart';
import '../../../../core/providers/auth_providers.dart';

final inventoryRepositoryProvider = Provider<InventoryRepositoryImpl>((ref) {
  final remoteDataSource =
      InventoryRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  return InventoryRepositoryImpl(remoteDataSource: remoteDataSource);
});

final articlesStreamProvider = StreamProvider<List<ArticleEntity>>((ref) {
  final organizationId = ref.watch(organizationIdProvider).value;
  final repository = ref.watch(inventoryRepositoryProvider);

  if (organizationId == null) {
    return Stream.value([]);
  }

  final getArticles = GetArticles(repository);
  return getArticles(organizationId);
});
