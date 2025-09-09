// lib/features/treasury/presentation/screens/treasury_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_providers.dart';
import 'treasury_history_screen.dart';

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trésorerie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TreasuryHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: paymentMethodsAsync.when(
        data: (methods) {
          final total = methods.fold<double>(0, (sum, m) => sum + m.balance);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Trésorerie Totale: ${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    final method = methods[index];
                    return ListTile(
                      title: Text(method.name),
                      trailing: Text(method.balance.toStringAsFixed(2)),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
