import '../entities/article_entity.dart';
import '../repositories/inventory_repository.dart';

class AddArticle {
  final InventoryRepository repository;
  AddArticle(this.repository);

  Future<ArticleEntity> call(String organizationId, ArticleEntity article) {
    return repository.addArticle(organizationId, article);
  }
}
