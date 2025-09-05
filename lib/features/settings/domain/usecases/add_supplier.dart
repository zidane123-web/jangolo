// lib/features/settings/domain/usecases/add_supplier.dart

import '../entities/management_entities.dart';
import '../repositories/settings_repository.dart';

class AddSupplier {
  final SettingsRepository repository;
  AddSupplier(this.repository);

  // Le Use Case prend l'ID de l'orga et le nom du nouveau fournisseur,
  // et retourne l'entité Supplier complète (avec son nouvel ID).
  Future<Supplier> call({
    required String organizationId,
    required String name,
  }) {
    return repository.addSupplier(organizationId: organizationId, name: name);
  }
}