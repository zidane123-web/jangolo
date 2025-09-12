// lib/features/sales/presentation/screens/sales_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // <-- 1. IMPORT DU NOUVEAU PACKAGE
import 'package:intl/intl.dart';

import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_line_entity.dart';
import '../providers/sales_providers.dart';
import 'create_sale_screen.dart';
import 'sale_detail_screen.dart';

// --- DONNÉES EN DUR POUR LA VISUALISATION ---
List<SaleEntity> _getHardcodedSales() {
  return [
    SaleEntity(
      id: 'V-001',
      customerId: 'CUST-001',
      customerName: 'Client Fidèle',
      createdAt: DateTime.now(),
      status: SaleStatus.completed,
      items: [
        const SaleLineEntity(
            id: 'L1-1',
            productId: 'P01',
            name: 'Coque Silicone iPhone 14',
            quantity: 1,
            unitPrice: 15000),
      ],
      createdBy: 'Alice Dubois',
      paymentStatus: 'Payé',
      hasDelivery: false,
    ),
    SaleEntity(
      id: 'V-002',
      customerId: 'CUST-002',
      customerName: 'Nouveau Client',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: SaleStatus.completed,
      items: [
        const SaleLineEntity(
            id: 'L2-1',
            productId: 'P02',
            name: 'Chargeur USB-C 20W',
            quantity: 2,
            unitPrice: 12500),
        const SaleLineEntity(
            id: 'L2-2',
            productId: 'P03',
            name: 'Câble USB-C vers Lightning',
            quantity: 1,
            unitPrice: 10000),
      ],
      createdBy: 'Bob Martin',
      paymentStatus: 'Partiel',
      hasDelivery: true,
    ),
    SaleEntity(
      id: 'V-003',
      customerId: 'CUST-003',
      customerName: 'Client Pro',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: SaleStatus.completed,
      items: [
        const SaleLineEntity(
            id: 'L3-1',
            productId: 'P04',
            name: 'Protection Écran Verre Trempé',
            quantity: 5,
            unitPrice: 7500),
      ],
      createdBy: 'Alice Dubois',
      paymentStatus: 'Non Payé',
      hasDelivery: false,
    ),
    SaleEntity(
      id: 'V-004',
      customerId: 'CUST-004',
      customerName: 'Visiteur Occasionnel',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: SaleStatus.draft,
      items: [
        const SaleLineEntity(
            id: 'L4-1',
            productId: 'P05',
            name: 'Écouteurs sans fil Pro',
            quantity: 1,
            unitPrice: 85000),
      ],
      createdBy: 'Carla C.',
      paymentStatus: 'En attente',
      hasDelivery: true,
    ),
  ];
}
// --- FIN DES DONNÉES EN DUR ---

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _money(double v, {String symbol = 'F'}) {
    final format = NumberFormat.currency(
        locale: 'fr_FR', symbol: symbol, decimalDigits: 0);
    return format.format(v);
  }

  double _calculateTodaySales(List<SaleEntity> sales) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final filteredSales = sales.where((sale) =>
        sale.createdAt.isAfter(startDate) &&
        sale.status == SaleStatus.completed);
    return filteredSales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(filteredSalesProvider);
    const primaryColor = Color(0xFF3b82f6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Ventes'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.filter_list)),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: primaryColor,
                indicatorWeight: 2.5,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Ventes directes'),
                  Tab(text: 'Livraisons'),
                ],
              ),
            ),
          ];
        },
        body: salesAsync.when(
          data: (sales) {
            final hardcodedSales = _getHardcodedSales();
            return TabBarView(
              controller: _tabController,
              children: [
                // Onglet 1: Ventes directes
                RefreshIndicator(
                  color: primaryColor,
                  backgroundColor: Colors.white,
                  strokeWidth: 3.0,
                  onRefresh: () async => ref.invalidate(salesStreamProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FilterChips(),
                            const SizedBox(height: 16),
                            _SalesSummaryBar(
                              totalSales: _calculateTodaySales(hardcodedSales),
                              moneyFormatter: _money,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      _SalesList(
                          sales: hardcodedSales, moneyFormatter: _money),
                    ],
                  ),
                ),
                // Onglet 2: Livraisons (placeholder)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Les ventes associées à des livraisons apparaîtront ici.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
      // --- 2. REMPLACEMENT DU BOUTON FLOTTANT ---
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        buttonSize: const Size(56.0, 56.0),
        childrenButtonSize: const Size(60.0, 60.0),
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.storefront_outlined),
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            label: 'Vente directe',
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateSaleScreen()));
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.local_shipping_outlined),
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            label: 'Livraison',
            onTap: () {
              // TODO: Naviguer vers l'écran de création de livraison
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Écran de livraison à créer')),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.request_quote_outlined),
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            label: 'Devis de ventes',
            onTap: () {
              // TODO: Naviguer vers l'écran de création de devis
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Écran de devis à créer')),
              );
            },
          ),
        ],
      ),
      // --- FIN DE LA MODIFICATION ---
    );
  }
}

// --- WIDGETS ---

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _FilterChip(label: 'Date'),
        const SizedBox(width: 8),
        _FilterChip(label: 'Produit'),
        const SizedBox(width: 8),
        _FilterChip(label: 'Client'),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () {},
      label: Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF374151)),
      ]),
      backgroundColor: const Color(0xFFF3F4F6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999), side: BorderSide.none),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}

class _SalesSummaryBar extends StatelessWidget {
  final double totalSales;
  final String Function(double, {String symbol}) moneyFormatter;

  const _SalesSummaryBar(
      {required this.totalSales, required this.moneyFormatter});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Résumé du jour ${moneyFormatter(totalSales, symbol: 'F')}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151)),
            ),
            const Icon(Icons.keyboard_arrow_up, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}

class _SalesList extends StatelessWidget {
  final List<SaleEntity> sales;
  final String Function(double, {String symbol}) moneyFormatter;

  const _SalesList({required this.sales, required this.moneyFormatter});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const Center(child: Text('Aucune vente à afficher.'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: sales.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sale = sales[index];
        return _SaleCard(sale: sale, moneyFormatter: moneyFormatter);
      },
    );
  }
}

class _SaleCard extends StatelessWidget {
  final SaleEntity sale;
  final String Function(double, {String symbol}) moneyFormatter;

  const _SaleCard({required this.sale, required this.moneyFormatter});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SaleDetailScreen(saleId: sale.id),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sale.customerName ?? 'Client Inconnu',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF111827)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    moneyFormatter(sale.grandTotal, symbol: 'F'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...sale.items.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(children: [
                      Text('${line.quantity.toStringAsFixed(0)}x',
                          style: const TextStyle(color: Color(0xFF6B7280))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(line.name ?? 'Produit',
                            style: const TextStyle(color: Color(0xFF6B7280))),
                      ),
                      Text(moneyFormatter(line.lineTotal, symbol: 'F'),
                          style: const TextStyle(color: Color(0xFF6B7280))),
                    ]),
                  )),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(sale.createdBy ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  const Spacer(),
                  Text(DateFormat('dd/MM/yy HH:mm').format(sale.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(width: 8),
                  _StatusPill(status: sale.paymentStatus ?? 'N/A'),
                ],
              ),
              if (sale.hasDelivery == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 16, color: Color(0xFF3b82f6)),
                      const SizedBox(width: 4),
                      Text('Livraison associée',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3b82f6),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color _getColor() {
    switch (status.toLowerCase()) {
      case 'payé':
        return Colors.green;
      case 'partiel':
        return Colors.orange;
      case 'non payé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}