import '../entities/article_entity.dart';
import '../repositories/inventory_repository.dart';

class SearchArticles {
  final InventoryRepository repository;
  SearchArticles(this.repository);

  Stream<List<ArticleEntity>> call({
    required String organizationId,
    required String query,
  }) {
    if (query.trim().isEmpty) {
      return Stream.value([]);
    }
    return repository.searchArticles(
        organizationId: organizationId, query: query);
  }
}
