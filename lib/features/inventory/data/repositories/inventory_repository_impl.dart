import '../../domain/entities/article_entity.dart';
import '../../domain/entities/movement_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../models/article_model.dart';
import '../models/movement_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ArticleEntity>> getArticles(String organizationId) {
    return remoteDataSource.getArticles(organizationId).map((models) {
      return models.map((m) => m as ArticleEntity).toList();
    });
  }

  @override
  Future<ArticleEntity> addArticle(String organizationId, ArticleEntity article) {
    final model = ArticleModel.fromEntity(article);
    return remoteDataSource.addArticle(organizationId, model);
  }

  @override
  Future<ArticleEntity?> getArticleBySku(
      String organizationId, String sku) {
    return remoteDataSource.getArticleBySku(organizationId, sku);
  }

  @override
  Future<void> updateArticle(
      String organizationId, ArticleEntity article) {
    final model = ArticleModel.fromEntity(article);
    return remoteDataSource.updateArticle(organizationId, model);
  }

  @override
  Future<void> addMovement(
      String organizationId, String articleId, MovementEntity movement) {
    final model = MovementModel.fromEntity(movement);
    return remoteDataSource.addMovement(organizationId, articleId, model);
  }

  @override
  Stream<List<MovementEntity>> getMovements(
      String organizationId, String articleId) {
    return remoteDataSource.getMovements(organizationId, articleId).map(
        (models) => models.map((m) => m as MovementEntity).toList());
  }
}
