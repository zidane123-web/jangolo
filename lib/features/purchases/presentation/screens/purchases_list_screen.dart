// lib/features/purchases/presentation/screens/purchases_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jangolo/features/settings/domain/entities/management_entities.dart';

import '../../domain/entities/purchase_entity.dart';
import '../providers/purchases_providers.dart';
import 'create_purchase_screen.dart';
import 'purchase_detail_screen.dart';

class PurchasesListScreen extends ConsumerStatefulWidget {
  const PurchasesListScreen({super.key});
  @override
  ConsumerState<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends ConsumerState<PurchasesListScreen>
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3b82f6);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const CreatePurchaseScreen()),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Achats'),
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
                  Tab(text: 'COMMANDES'),
                  Tab(text: 'STATISTIQUES'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // --- Onglet 1: Commandes ---
            const _OrdersTab(),
            // --- Onglet 2: Statistiques (Placeholder) ---
            const Center(
              child: Text('Les statistiques des achats apparaîtront ici.'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS SPÉCIFIQUES ---

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  String _money(double v, {String symbol = 'F'}) {
    final format = NumberFormat.currency(
        locale: 'fr_FR', symbol: symbol, decimalDigits: 0);
    return format.format(v);
  }

  double _calculateTotalDebt(List<PurchaseEntity> purchases) {
    return purchases.fold(0.0, (sum, purchase) => sum + purchase.balanceDue);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesStreamProvider);
    return purchasesAsync.when(
      data: (purchases) { // ✅ ON UTILISE MAINTENANT LES VRAIES DONNÉES
        return RefreshIndicator(
          color: const Color(0xFF3b82f6),
          backgroundColor: Colors.white,
          onRefresh: () async => ref.invalidate(purchasesStreamProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    _FilterChips(),
                    const SizedBox(height: 24),
                    _PurchasesSummaryBar(
                      totalDebt: _calculateTotalDebt(purchases), // ✅ UTILISATION DES VRAIES DONNÉES
                      moneyFormatter: _money,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              _PurchasesList(
                purchases: purchases, // ✅ UTILISATION DES VRAIES DONNÉES
                moneyFormatter: _money,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _FilterChip(label: 'Date'),
        const SizedBox(width: 8),
        _FilterChip(label: 'Fournisseur'),
        const SizedBox(width: 8),
        _FilterChip(label: 'Statut'),
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

class _PurchasesSummaryBar extends StatelessWidget {
  final double totalDebt;
  final String Function(double, {String symbol}) moneyFormatter;

  const _PurchasesSummaryBar(
      {required this.totalDebt, required this.moneyFormatter});

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
              'Dettes fournisseurs ${moneyFormatter(totalDebt, symbol: 'F')}',
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

class _PurchasesList extends StatelessWidget {
  final List<PurchaseEntity> purchases;
  final String Function(double, {String symbol}) moneyFormatter;

  const _PurchasesList({required this.purchases, required this.moneyFormatter});

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 64.0),
        child: Center(child: Text('Aucun achat à afficher.')),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: purchases.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return _PurchaseCard(
            purchase: purchase, moneyFormatter: moneyFormatter);
      },
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final PurchaseEntity purchase;
  final String Function(double, {String symbol}) moneyFormatter;

  const _PurchaseCard({required this.purchase, required this.moneyFormatter});
  
  Route _createSlideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

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
          Navigator.of(context).push(_createSlideTransition(
            PurchaseDetailScreen(purchaseId: purchase.id),
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
                      purchase.supplier.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF111827)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    moneyFormatter(purchase.grandTotal, symbol: 'F'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '#${purchase.id}',
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(purchase.createdByName ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  const Spacer(),
                  Text(DateFormat('dd/MM/yy HH:mm').format(purchase.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(width: 8),
                  _StatusPill(status: purchase.balanceDue > 0.01 ? 'Non Payé' : 'Payé'),
                ],
              ),
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