// lib/features/settings/presentation/screens/payment_methods_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/settings_providers.dart';
import 'add_edit_payment_method_screen.dart';
import '../../domain/usecases/delete_payment_method.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../../../core/providers/auth_providers.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  late final DeletePaymentMethod _deletePaymentMethod;

  @override
  void initState() {
    super.initState();
    final remoteDataSource =
        SettingsRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository = SettingsRepositoryImpl(remoteDataSource: remoteDataSource);
    _deletePaymentMethod = DeletePaymentMethod(repository);
  }

  Future<void> _onDelete(BuildContext context, String methodId) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmer'),
            content: const Text('Supprimer ce moyen de paiement ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    try {
      final organizationId = ref.read(organizationIdProvider).value;
      if (organizationId == null) throw Exception('Organisation non trouvée');
      await _deletePaymentMethod(
        organizationId: organizationId,
        methodId: methodId,
      );
      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moyens de paiement'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditPaymentMethodScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: paymentMethodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return const Center(child: Text('Aucun moyen de paiement'));
          }
          return ListView.builder(
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return ListTile(
                title: Text(method.name),
                subtitle:
                    Text('Solde: ${method.balance.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditPaymentMethodScreen(method: method),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _onDelete(context, method.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
