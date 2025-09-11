// lib/features/sales/presentation/screens/sales_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sale_entity.dart';
import '../providers/sales_providers.dart';
import 'create_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends ConsumerWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ventes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: salesAsync.when(
        data: (sales) => _SalesList(sales: sales),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _SalesList extends StatelessWidget {
  final List<SaleEntity> sales;
  const _SalesList({required this.sales});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const Center(child: Text('Aucune vente')); 
    }
    return ListView.builder(
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return ListTile(
          title: Text(sale.customerName ?? 'Client inconnu'),
          subtitle: Text('Total: ${sale.grandTotal.toStringAsFixed(2)}'),
          trailing: Text(sale.status.name),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => SaleDetailScreen(saleId: sale.id)),
            );
          },
        );
      },
    );
  }
}
