// lib/features/sales/domain/repositories/client_repository.dart

import '../entities/client_entity.dart';

abstract class ClientRepository {
  Stream<List<ClientEntity>> getClients(String organizationId);
  Future<ClientEntity> addClient(
      String organizationId, ClientEntity client);
}
