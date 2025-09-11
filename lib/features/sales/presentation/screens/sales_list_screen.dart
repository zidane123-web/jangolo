// lib/features/sales/presentation/screens/sales_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/sale_entity.dart';
import '../providers/sales_providers.dart';
import 'create_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends ConsumerWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(filteredSalesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventes'),
        actions: [
          PopupMenuButton<SaleStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) =>
                ref.read(salesStatusFilterProvider.notifier).state = status,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Toutes'),
              ),
              ...SaleStatus.values.map(
                (s) => PopupMenuItem(
                  value: s,
                  child: Text(_statusLabel(s)),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) =>
                  ref.read(salesSearchProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Rechercher une vente',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(salesStreamProvider);
        },
        child: salesAsync.when(
          data: (sales) => _SalesList(sales: sales),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }
}

class _SalesList extends StatelessWidget {
  final List<SaleEntity> sales;
  const _SalesList({required this.sales});

  Color _statusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed:
        return Colors.green;
      case SaleStatus.cancelled:
        return Colors.red;
      case SaleStatus.draft:
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const Center(child: Text('Aucune vente'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sale = sales[index];
        final statusColor = _statusColor(sale.status);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                (sale.customerName?.isNotEmpty ?? false)
                    ? sale.customerName![0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text(
              sale.customerName ?? 'Client inconnu',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(sale.createdAt),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${sale.grandTotal.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(sale.status),
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => SaleDetailScreen(saleId: sale.id)),
              );
            },
          ),
        );
      },
    );
  }
}

String _statusLabel(SaleStatus status) {
  switch (status) {
    case SaleStatus.completed:
      return 'Complétée';
    case SaleStatus.cancelled:
      return 'Annulée';
    case SaleStatus.draft:
    default:
      return 'Brouillon';
  }
}
