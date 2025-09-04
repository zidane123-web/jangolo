// lib/features/purchases/domain/repositories/purchase_repository.dart

import '../entities/purchase_entity.dart';

abstract class PurchaseRepository {
  /// Récupère la liste de tous les bons de commande pour une organisation.
  /// Le stream permet à l'interface de se mettre à jour en temps réel.
  Stream<List<PurchaseEntity>> getAllPurchases(String organizationId);

  /// Récupère les détails d'un bon de commande spécifique.
  Future<PurchaseEntity?> getPurchaseDetails({
    required String organizationId,
    required String purchaseId,
  });

  /// Crée un nouveau bon de commande.
  /// L'entité passée en paramètre contient toutes les informations nécessaires.
  Future<void> createPurchase({
    required String organizationId,
    required PurchaseEntity purchase,
  });

  /// Met à jour un bon de commande existant.
  Future<void> updatePurchase({
    required String organizationId,
    required PurchaseEntity purchase,
  });

  /// Supprime un bon de commande.
  Future<void> deletePurchase({
    required String organizationId,
    required String purchaseId,
  });
}