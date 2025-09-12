// lib/features/sales/domain/usecases/add_client.dart

import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class AddClient {
  final ClientRepository repository;

  AddClient(this.repository);

  Future<ClientEntity> call({
    required String organizationId,
    required ClientEntity client,
  }) {
    return repository.addClient(organizationId, client);
  }
}
