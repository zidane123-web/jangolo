// lib/features/settings/presentation/screens/add_edit_payment_method_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/management_entities.dart';
import '../../domain/usecases/add_payment_method.dart';
import '../../domain/usecases/update_payment_method.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../providers/settings_providers.dart';
import '../../../../core/providers/auth_providers.dart';

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
  bool _isSaving = false;

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

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final organizationId = ref.read(organizationIdProvider).value;
      if (organizationId == null) throw Exception('Organisation non trouvée');

      final remoteDataSource =
          SettingsRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
      final repository =
          SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
      final addPaymentMethod = AddPaymentMethod(repository);
      final updatePaymentMethod = UpdatePaymentMethod(repository);

      if (widget.method == null) {
        await addPaymentMethod(
          organizationId: organizationId,
          name: _nameController.text,
          type: _typeController.text,
          initialBalance:
              double.tryParse(_balanceController.text.trim()) ?? 0.0,
        );
      } else {
        await updatePaymentMethod(
          organizationId: organizationId,
          method: PaymentMethod(
            id: widget.method!.id,
            name: _nameController.text,
            type: _typeController.text,
            balance:
                double.tryParse(_balanceController.text.trim()) ?? widget.method!.balance,
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      setState(() => _isSaving = false);
    }
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
                onPressed: _isSaving ? null : _onSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
