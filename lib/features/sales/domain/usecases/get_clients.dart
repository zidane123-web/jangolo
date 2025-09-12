// lib/features/sales/domain/usecases/get_clients.dart

import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class GetClients {
  final ClientRepository repository;

  GetClients(this.repository);

  Stream<List<ClientEntity>> call(String organizationId) {
    return repository.getClients(organizationId);
  }
}
