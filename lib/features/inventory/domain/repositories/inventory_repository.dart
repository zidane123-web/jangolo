import '../entities/article_entity.dart';
import '../entities/movement_entity.dart';

abstract class InventoryRepository {
  /// Returns a real-time stream of all articles for a given organization.
  Stream<List<ArticleEntity>> getArticles(String organizationId);

  /// Creates a new article for the organization and returns the created entity.
  Future<ArticleEntity> addArticle(String organizationId, ArticleEntity article);

  /// Fetches a single article by its SKU (ID).
  Future<ArticleEntity?> getArticleBySku(String organizationId, String sku);

  /// Updates an existing article's data.
  Future<void> updateArticle(String organizationId, ArticleEntity article);

  Future<void> addMovement(
      String organizationId, String articleId, MovementEntity movement);

  Stream<List<MovementEntity>> getMovements(
      String organizationId, String articleId);
}
