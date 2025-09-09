// lib/features/settings/presentation/screens/warehouses_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/management_entities.dart';
import '../../domain/usecases/add_warehouse.dart';
import '../../domain/usecases/delete_warehouse.dart';
import '../../domain/usecases/update_warehouse.dart';
import '../providers/settings_providers.dart';
import 'add_edit_warehouse_screen.dart';
import '../../../../core/providers/auth_providers.dart';

class WarehousesListScreen extends ConsumerStatefulWidget {
  const WarehousesListScreen({super.key});

  @override
  ConsumerState<WarehousesListScreen> createState() => _WarehousesListScreenState();
}

class _WarehousesListScreenState extends ConsumerState<WarehousesListScreen> {
  late final AddWarehouse _addWarehouse;
  late final UpdateWarehouse _updateWarehouse;
  late final DeleteWarehouse _deleteWarehouse;

  @override
  void initState() {
    super.initState();
    final remoteDataSource =
        SettingsRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository =
        SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
    _addWarehouse = AddWarehouse(repository);
    _updateWarehouse = UpdateWarehouse(repository);
    _deleteWarehouse = DeleteWarehouse(repository);
  }

  Future<void> _navigateAndUpsert({Warehouse? warehouse}) async {
    final result = await Navigator.of(context).push<Warehouse>(
      MaterialPageRoute(builder: (_) => AddEditWarehouseScreen(warehouse: warehouse)),
    );
    if (result != null) {
      final organizationId = ref.read(organizationIdProvider).value;
      if (organizationId == null) return;
      try {
        if (warehouse != null) {
          // Mode édition
          await _updateWarehouse(
              organizationId: organizationId, warehouse: result);
        } else {
          // Mode création
          await _addWarehouse(
              organizationId: organizationId,
              name: result.name,
              address: result.address);
        }
        ref.invalidate(warehousesProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Erreur: $e")));
        }
      }
    }
  }

  Future<void> _confirmDelete(Warehouse warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer l\'entrepôt "${warehouse.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirmed == true) {
      final organizationId = ref.read(organizationIdProvider).value;
      if (organizationId == null) return;
      try {
        await _deleteWarehouse(
            organizationId: organizationId, warehouseId: warehouse.id);
        ref.invalidate(warehousesProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Erreur: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrepôts'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(warehousesProvider);
        },
        child: ref.watch(warehousesProvider).when(
              data: (warehouses) {
                if (warehouses.isEmpty) {
                  return const Center(
                      child: Text(
                          "Aucun entrepôt. Cliquez sur '+' pour en ajouter un."));
                }
                return ListView.builder(
                  itemCount: warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = warehouses[index];
                    return ListTile(
                      leading: const Icon(Icons.home_work_outlined),
                      title: Text(warehouse.name),
                      subtitle: warehouse.address != null &&
                              warehouse.address!.isNotEmpty
                          ? Text(warehouse.address!)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _navigateAndUpsert(warehouse: warehouse)),
                          IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error),
                              onPressed: () =>
                                  _confirmDelete(warehouse)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (err, _) => Center(
                  child: Text(
                      "Erreur de chargement:\n$err",
                      textAlign: TextAlign.center)),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndUpsert(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel Entrepôt'),
      ),
    );
  }
}