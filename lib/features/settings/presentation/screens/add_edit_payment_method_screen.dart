// lib/features/settings/presentation/screens/add_edit_payment_method_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/management_entities.dart';

class AddEditPaymentMethodScreen extends ConsumerStatefulWidget {
  final PaymentMethod? method;
  const AddEditPaymentMethodScreen({super.key, this.method});

  @override
  ConsumerState<AddEditPaymentMethodScreen> createState() => _AddEditPaymentMethodScreenState();
}

class _AddEditPaymentMethodScreenState extends ConsumerState<AddEditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.method?.name ?? '');
    _typeController = TextEditingController(text: widget.method?.type ?? 'cash');
    _balanceController = TextEditingController(
        text: widget.method != null ? widget.method!.balance.toString() : '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.method != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier un moyen' : 'Ajouter un moyen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                    labelText: isEdit ? 'Solde actuel' : 'Solde initial'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
