import '../entities/article_entity.dart';
import '../repositories/inventory_repository.dart';

class GetArticles {
  final InventoryRepository repository;

  GetArticles(this.repository);

  Stream<List<ArticleEntity>> call(String organizationId) {
    return repository.getArticles(organizationId);
  }
}
