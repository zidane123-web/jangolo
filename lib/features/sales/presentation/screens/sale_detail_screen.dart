// lib/features/sales/presentation/screens/sale_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sale_entity.dart';
import '../providers/sales_providers.dart';

class SaleDetailScreen extends ConsumerWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Détails vente')),
      body: saleAsync.when(
        data: (sale) {
          if (sale == null) {
            return const Center(child: Text('Vente introuvable'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                sale.customerName ?? sale.customerId,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Statut: ${sale.status.name}'),
              const SizedBox(height: 8),
              Text('Total: ${sale.grandTotal.toStringAsFixed(2)}'),
              const Divider(),
              ...sale.items.map(
                (item) => ListTile(
                  title: Text(item.name ?? item.productId),
                  subtitle: Text('Qté: ${item.quantity} x ${item.unitPrice}'),
                  trailing: Text(item.lineTotal.toStringAsFixed(2)),
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
