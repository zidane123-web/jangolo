// lib/features/sales/domain/entities/client_entity.dart

/// Représente un client.
class ClientEntity {
  final String id;
  final String name;
  final String? phone;
  final String? address;

  const ClientEntity({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });
}
