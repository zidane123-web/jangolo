import '../entities/article_entity.dart';
import '../repositories/inventory_repository.dart';

class GetArticleBySku {
  final InventoryRepository repository;
  GetArticleBySku(this.repository);

  Future<ArticleEntity?> call({
    required String organizationId,
    required String sku,
  }) {
    return repository.getArticleBySku(organizationId, sku);
  }
}
