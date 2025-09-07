import '../entities/movement_entity.dart';
import '../repositories/inventory_repository.dart';

class GetMovements {
  final InventoryRepository repository;
  GetMovements(this.repository);

  Stream<List<MovementEntity>> call(
      String organizationId, String articleId) {
    return repository.getMovements(organizationId, articleId);
  }
}
