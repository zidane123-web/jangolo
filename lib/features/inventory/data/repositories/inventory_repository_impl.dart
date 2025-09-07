import '../../domain/entities/article_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ArticleEntity>> getArticles(String organizationId) {
    return remoteDataSource.getArticles(organizationId).map((models) {
      return models.map((m) => m as ArticleEntity).toList();
    });
  }
}
