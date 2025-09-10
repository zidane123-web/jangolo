import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/purchase_entity.dart';
import '../providers/purchases_providers.dart';

import 'create_purchase_screen.dart';
import 'purchase_detail_screen.dart';

// L'enum de filtre reste local à cet écran
enum _FilterStatus { paid, unpaid, draft }

class PurchasesListScreen extends ConsumerStatefulWidget {
  const PurchasesListScreen({super.key});
  @override
  ConsumerState<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends ConsumerState<PurchasesListScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedDate = DateTime.now(); // Déplacé ici

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
  
  // Déplacé ici
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Achats', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          _DateFilterChip(
            selectedDate: _selectedDate,
            onTap: _selectDate,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Rechercher',
            onPressed: () => _snack('Recherche à implémenter'),
            icon: const Icon(Icons.search, color: Colors.black54),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'COMMANDES'),
            Tab(text: 'STATISTIQUES'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const CreatePurchaseScreen()),
          );
        },
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Nouvel Achat'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _OrdersTab(
            selectedDate: _selectedDate,
          ),
          const _StatsTab(),
        ],
      ),
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ================== Onglet des Commandes =====================================
class _OrdersTab extends ConsumerStatefulWidget {
  final DateTime selectedDate; // Ajouté
  const _OrdersTab({required this.selectedDate}); // Ajouté

  @override
  ConsumerState<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<_OrdersTab>
    with AutomaticKeepAliveClientMixin {
  _FilterStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final purchasesAsync = ref.watch(purchasesStreamProvider);

    return purchasesAsync.when(
      data: (allPurchases) {
        if (allPurchases.isEmpty) {
          return const Center(child: Text("Aucun achat trouvé."));
        }
        final filteredList = _filterPurchases(allPurchases);
        final stats = _computeStats(allPurchases);
        return _buildPurchaseList(filteredList, stats);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Erreur: $err")),
    );
  }

  List<PurchaseEntity> _filterPurchases(List<PurchaseEntity> allPurchases) {
    return allPurchases.where((p) {
      final statusMatch = _statusFilter == null || _matchesFilter(p.status, _statusFilter!);
      final dateMatch = _isSameDay(p.createdAt, widget.selectedDate);
      return statusMatch && dateMatch;
    }).toList();
  }
  
  bool _matchesFilter(PurchaseStatus purchaseStatus, _FilterStatus filter) {
    switch (filter) {
      case _FilterStatus.paid:
        return purchaseStatus == PurchaseStatus.paid;
      case _FilterStatus.draft:
        return purchaseStatus == PurchaseStatus.draft;
      case _FilterStatus.unpaid:
        return purchaseStatus != PurchaseStatus.paid && purchaseStatus != PurchaseStatus.draft;
    }
  }

  _PStats _computeStats(List<PurchaseEntity> list) {
    final open = list.where((p) => p.status != PurchaseStatus.paid && p.status != PurchaseStatus.received).toList();
    final debt = open.fold(0.0, (sum, p) => sum + p.balanceDue);
    return _PStats(openCount: open.length, supplierDebt: debt);
  }

  Widget _buildPurchaseList(List<PurchaseEntity> list, _PStats stats) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(purchasesStreamProvider);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _KpiGrid(children: [
                _KpiCard(
                  icon: Icons.move_to_inbox_outlined,
                  label: 'À réceptionner',
                  value: '${stats.openCount}',
                ),
                _KpiCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Dettes fournisseurs',
                  value: _money(stats.supplierDebt),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _StatusChips(
                current: _statusFilter,
                onChanged: (s) => setState(() => _statusFilter = s),
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("Aucun achat trouvé pour cette date."),
              )),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), 
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  return _PurchaseCard(purchase: list[i]);
                },
              ),
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  
  String _money(double v) => NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(v);

  @override
  bool get wantKeepAlive => true;
}

// ================== Onglet des Statistiques (inchangé) ==================================
class _StatsTab extends StatelessWidget {
  const _StatsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Page des statistiques à venir.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}


// ==== WIDGETS INTERNES =======================================================

class _PurchaseCard extends StatelessWidget {
  final PurchaseEntity purchase;
  const _PurchaseCard({required this.purchase});

  String _d(DateTime d) => DateFormat('dd MMM yyyy', 'fr_FR').format(d);
  String _money(double v) => NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(v);
  
  String _statusLabel(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft: return 'Brouillon';
      case PurchaseStatus.approved: return 'Validée';
      case PurchaseStatus.sent: return 'Envoyée';
      case PurchaseStatus.partial: return 'Partielle';
      case PurchaseStatus.received: return 'Réceptionnée';
      case PurchaseStatus.invoiced: return 'Facturée';
      case PurchaseStatus.paid: return 'Payée';
    }
  }

  Color _statusColor(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.paid:
        return const Color(0xFF34A853); // Vert (Succès)
      case PurchaseStatus.partial:
        return const Color(0xFFF9AB00); // Ambre (Avertissement)
      case PurchaseStatus.draft:
        return Colors.blueGrey; // Gris (Neutre)
      // Pour tous les autres statuts "en cours"
      case PurchaseStatus.approved:
      case PurchaseStatus.sent:
      case PurchaseStatus.received:
      case PurchaseStatus.invoiced:
      default:
        return const Color(0xFF4285F4); // Bleu (Information)
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bool isUnpaid = purchase.balanceDue > 0.01;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PurchaseDetailScreen(purchaseId: purchase.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.supplier.name,
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${purchase.id}',
                        style: tt.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _money(purchase.grandTotal),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatusBadge(
                  label: isUnpaid ? 'Solde Dû: ${_money(purchase.balanceDue)}' : 'Payé',
                  color: isUnpaid ? const Color(0xFFF9AB00) : const Color(0xFF34A853),
                  icon: isUnpaid ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline,
                ),
                _StatusBadge(
                  label: _statusLabel(purchase.status),
                  color: _statusColor(purchase.status),
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Entrepôt: ${purchase.warehouse.name}',
                  style: tt.bodySmall?.copyWith(color: Colors.black54),
                ),
                Text(
                  'ETA: ${_d(purchase.eta)}',
                  style: tt.bodySmall?.copyWith(
                    color: purchase.isLate ? const Color(0xFFEA4335) : Colors.black54,
                    fontWeight: purchase.isLate ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


class _PStats {
  final int openCount;
  final double supplierDebt;
  const _PStats({required this.openCount, required this.supplierDebt});
}

class _DateFilterChip extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  const _DateFilterChip({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isToday = _isToday(selectedDate);
    final label = isToday ? "Aujourd'hui" : DateFormat('d MMM yyyy', 'fr_FR').format(selectedDate);

    return ActionChip(
      onPressed: onTap,
      elevation: 0,
      avatar: Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
      label: Text(label),
      labelStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _KpiGrid extends StatelessWidget {
  final List<Widget> children;
  const _KpiGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      primary: false,
      children: children,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _KpiCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueGrey.withAlpha(20),
            foregroundColor: Colors.blueGrey,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.labelMedium?.copyWith(color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final _FilterStatus? current;
  final ValueChanged<_FilterStatus?> onChanged;
  const _StatusChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = <_FilterStatus?, String>{
      null: 'Tous',
      _FilterStatus.paid: 'Réglé',
      _FilterStatus.unpaid: 'Non réglé',
      _FilterStatus.draft: 'Brouillon',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final filter = entry.key;
          final label = entry.value;
          final isSelected = current == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(filter),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blueGrey.shade50,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blueGrey.shade800 : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
              side: BorderSide(color: isSelected ? Colors.blueGrey.shade200 : Colors.grey.shade200),
              elevation: 0,
            ),
          );
        }).toList(),
      ),
    );
  }
}