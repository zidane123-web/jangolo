// lib/features/settings/presentation/screens/warehouses_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/management_entities.dart';
import '../../domain/usecases/add_warehouse.dart';
import '../../domain/usecases/delete_warehouse.dart';
import '../../domain/usecases/get_management_data.dart';
import '../../domain/usecases/update_warehouse.dart';
import 'add_edit_warehouse_screen.dart';

class WarehousesListScreen extends StatefulWidget {
  const WarehousesListScreen({super.key});

  @override
  State<WarehousesListScreen> createState() => _WarehousesListScreenState();
}

class _WarehousesListScreenState extends State<WarehousesListScreen> {
  late final GetWarehouses _getWarehouses;
  late final AddWarehouse _addWarehouse;
  late final UpdateWarehouse _updateWarehouse;
  late final DeleteWarehouse _deleteWarehouse;
  
  String? _organizationId;
  List<Warehouse>? _warehouses;
  String? _error;

  @override
  void initState() {
    super.initState();
    final remoteDataSource = SettingsRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository = SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
    _getWarehouses = GetWarehouses(repository);
    _addWarehouse = AddWarehouse(repository);
    _updateWarehouse = UpdateWarehouse(repository);
    _deleteWarehouse = DeleteWarehouse(repository);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _warehouses = null;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non authentifié.");
      
      final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
      _organizationId = userDoc.data()?['organizationId'] as String?;
      if (_organizationId == null) throw Exception("Organisation non trouvée.");

      final warehouses = await _getWarehouses(_organizationId!);
      setState(() {
        _warehouses = warehouses;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _navigateAndUpsert({Warehouse? warehouse}) async {
    final result = await Navigator.of(context).push<Warehouse>(
      MaterialPageRoute(builder: (_) => AddEditWarehouseScreen(warehouse: warehouse)),
    );

    if (result != null && _organizationId != null) {
      try {
        if (warehouse != null) { // Mode édition
          await _updateWarehouse(organizationId: _organizationId!, warehouse: result);
        } else { // Mode création
          await _addWarehouse(organizationId: _organizationId!, name: result.name, address: result.address);
        }
        _loadData(); // Recharger la liste
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
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
          FilledButton(onPressed: () => Navigator.of(context).pop(true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirmed == true && _organizationId != null) {
      try {
        await _deleteWarehouse(organizationId: _organizationId!, warehouseId: warehouse.id);
        _loadData();
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
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
        onRefresh: _loadData,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndUpsert(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel Entrepôt'),
      ),
    );
  }

  Widget _buildBody() {
    if (_warehouses == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text("Erreur de chargement:\n$_error", textAlign: TextAlign.center));
    }
    if (_warehouses!.isEmpty) {
      return const Center(child: Text("Aucun entrepôt. Cliquez sur '+' pour en ajouter un."));
    }
    return ListView.builder(
      itemCount: _warehouses!.length,
      itemBuilder: (context, index) {
        final warehouse = _warehouses![index];
        return ListTile(
          leading: const Icon(Icons.home_work_outlined),
          title: Text(warehouse.name),
          subtitle: warehouse.address != null && warehouse.address!.isNotEmpty ? Text(warehouse.address!) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _navigateAndUpsert(warehouse: warehouse)),
              IconButton(icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), onPressed: () => _confirmDelete(warehouse)),
            ],
          ),
        );
      },
    );
  }
}