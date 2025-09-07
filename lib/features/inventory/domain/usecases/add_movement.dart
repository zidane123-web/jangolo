import '../entities/movement_entity.dart';
import '../repositories/inventory_repository.dart';

class AddMovement {
  final InventoryRepository repository;
  AddMovement(this.repository);

  Future<void> call(
      String organizationId, String articleId, MovementEntity movement) {
    return repository.addMovement(organizationId, articleId, movement);
  }
}
