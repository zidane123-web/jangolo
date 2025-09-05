// lib/features/settings/domain/entities/management_entities.dart

/// Représente un fournisseur.
class Supplier {
  final String id;
  final String name;
  final String? contact;
  final String? phone;

  const Supplier({
    required this.id,
    required this.name,
    this.contact,
    this.phone,
  });
}

/// Représente un entrepôt ou un lieu de stockage.
class Warehouse {
  final String id;
  final String name;
  final String? address;

  const Warehouse({
    required this.id,
    required this.name,
    this.address,
  });
}

/// Représente un moyen/compte de paiement.
class PaymentMethod {
  final String id;
  final String name; // ex: "Caisse Principale", "MTN Mobile Money"
  final String type; // ex: "cash", "momo", "bank"

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
  });
}