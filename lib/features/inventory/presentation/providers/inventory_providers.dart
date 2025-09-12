import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/article_entity.dart';
import '../../domain/entities/movement_entity.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../domain/usecases/get_article_by_sku.dart';
import '../../domain/usecases/get_articles.dart';
import '../../domain/usecases/get_movements.dart';
import '../../domain/usecases/search_articles.dart';
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

final movementsStreamProvider =
    StreamProvider.family<List<MovementEntity>, String>((ref, sku) {
  final organizationId = ref.watch(organizationIdProvider).value;
  final repository = ref.watch(inventoryRepositoryProvider);

  if (organizationId == null) {
    return Stream.value([]);
  }

  final getMovements = GetMovements(repository);
  return getMovements(organizationId, sku);
});

/// Provides a use case to fetch a single article by its SKU.
final getArticleBySkuProvider = Provider.autoDispose<GetArticleBySku>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return GetArticleBySku(repository);
});

/// Provides a use case to search articles with a query string.
final searchArticlesProvider =
    Provider.autoDispose.family<SearchArticles, String>((ref, query) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return SearchArticles(repository);
});
