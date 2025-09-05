// lib/features/settings/domain/usecases/add_supplier.dart

import '../entities/management_entities.dart';
import '../repositories/settings_repository.dart';

class AddSupplier {
  final SettingsRepository repository;
  AddSupplier(this.repository);

  // Le Use Case prend l'ID de l'orga, le nom et le téléphone (optionnel),
  // et retourne l'entité Supplier complète (avec son nouvel ID).
  Future<Supplier> call({
    required String organizationId,
    required String name,
    String? phone,
  }) {
    return repository.addSupplier(organizationId: organizationId, name: name, phone: phone);
  }
}