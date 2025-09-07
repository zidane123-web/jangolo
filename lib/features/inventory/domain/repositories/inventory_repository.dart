import '../entities/article_entity.dart';

abstract class InventoryRepository {
  /// Returns a real-time stream of all articles for a given organization.
  Stream<List<ArticleEntity>> getArticles(String organizationId);

  /// Creates a new article for the organization and returns the created entity.
  Future<ArticleEntity> addArticle(String organizationId, ArticleEntity article);
}
