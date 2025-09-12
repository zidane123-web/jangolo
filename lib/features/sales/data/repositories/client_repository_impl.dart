// lib/features/sales/data/repositories/client_repository_impl.dart

import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/remote_datasource.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final SalesRemoteDataSource remoteDataSource;

  ClientRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ClientEntity>> getClients(String organizationId) {
    return remoteDataSource.getClients(organizationId);
  }

  @override
  Future<ClientEntity> addClient(
      String organizationId, ClientEntity client) {
    final clientModel = ClientModel(
      id: client.id,
      name: client.name,
      phone: client.phone,
      address: client.address,
    );
    return remoteDataSource.addClient(organizationId, clientModel);
  }
}
