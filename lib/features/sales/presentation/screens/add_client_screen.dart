// lib/features/sales/presentation/screens/add_client_screen.dart

import 'package:flutter/material.dart';

import '../../domain/entities/client_entity.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // --- LOGIQUE FICTIVE ---
    // Simule une sauvegarde et renvoie le nouveau client.
    await Future.delayed(const Duration(milliseconds: 500));
    final newClient = ClientEntity(
      id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
    );
    // --- FIN LOGIQUE FICTIVE ---

    if (mounted) {
      Navigator.of(context).pop(newClient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Client'),
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
                  labelText: 'Nom du client *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed: _onSave,
                      style:
                          FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
