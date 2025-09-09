// lib/features/settings/presentation/screens/payment_methods_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';
import 'add_edit_payment_method_screen.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                subtitle: Text('Solde: ${method.balance.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditPaymentMethodScreen(method: method),
                    ),
                  );
                },
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
