// lib/features/settings/presentation/screens/add_supplier_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/management_entities.dart';
import '../../domain/usecases/add_supplier.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // ✅ Contrôleur pour le téléphone
  bool _isSaving = false;

  late final AddSupplier _addSupplier;

  @override
  void initState() {
    super.initState();
    // Injection de dépendances simplifiée
    final remoteDataSource = SettingsRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository = SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
    _addSupplier = AddSupplier(repository);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose(); // ✅ Ne pas oublier de le libérer
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non authentifié.");
      
      final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
      final organizationId = userDoc.data()?['organizationId'] as String?;
      if (organizationId == null) throw Exception("Organisation non trouvée.");

      // ✅ On récupère le nom et le téléphone pour les passer au cas d'utilisation
      final phone = _phoneController.text.trim();

      final newSupplier = await _addSupplier(
        organizationId: organizationId,
        name: _nameController.text.trim(),
        phone: phone.isNotEmpty ? phone : null, // On passe null si le champ est vide
      );

      if (mounted) {
        // On renvoie le nouveau fournisseur à l'écran précédent
        Navigator.of(context).pop(newSupplier);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Fournisseur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du fournisseur *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store_mall_directory_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // ✅ Ajout du champ téléphone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed: _onSave,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Enregistrer'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}