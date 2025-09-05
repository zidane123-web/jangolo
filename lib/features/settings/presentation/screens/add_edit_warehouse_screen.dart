// lib/features/settings/presentation/screens/add_edit_warehouse_screen.dart

import 'package:flutter/material.dart';
import '../../domain/entities/management_entities.dart';

class AddEditWarehouseScreen extends StatefulWidget {
  final Warehouse? warehouse;

  const AddEditWarehouseScreen({super.key, this.warehouse});

  @override
  State<AddEditWarehouseScreen> createState() => _AddEditWarehouseScreenState();
}

class _AddEditWarehouseScreenState extends State<AddEditWarehouseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  bool get _isEditing => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warehouse?.name);
    _addressController = TextEditingController(text: widget.warehouse?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final result = Warehouse(
        id: widget.warehouse?.id ?? '', // L'ID sera ignoré si création
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
      );
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'entrepôt' : 'Nouvel Entrepôt'),
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
                  labelText: 'Nom de l\'entrepôt *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_work_outlined),
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
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
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