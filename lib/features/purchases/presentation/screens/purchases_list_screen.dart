import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/usecases/get_all_purchases.dart';

import 'create_purchase_screen.dart';

// L'enum de filtre reste local à cet écran
enum _FilterStatus { paid, unpaid, draft }

class PurchasesListScreen extends StatefulWidget {
  const PurchasesListScreen({super.key});
  @override
  State<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends State<PurchasesListScreen>
    with TickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
        title: const Text('Achats'),
        actions: [
          IconButton(
            tooltip: 'Rechercher',
            onPressed: () => _snack('Recherche à implémenter'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Nouveau bon de commande',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const CreatePurchaseScreen()),
              );
            },
            icon: const Icon(Icons.add_shopping_cart_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'COMMANDES'),
            Tab(text: 'STATISTIQUES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          _OrdersTab(),
          _StatsTab(),
        ],
      ),
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ================== Onglet des Commandes (entièrement refactorisé) =====================================
class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab>
    with AutomaticKeepAliveClientMixin {
      
  late final GetAllPurchases _getAllPurchases;
  Future<String?>? _organizationIdFuture;

  _FilterStatus? _statusFilter;
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    final remoteDataSource = PurchaseRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository = PurchaseRepositoryImpl(remoteDataSource: remoteDataSource);
    _getAllPurchases = GetAllPurchases(repository);

    _organizationIdFuture = _getOrganizationId();
  }
  
  Future<String?> _getOrganizationId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid).get();
    return userDoc.data()?['organizationId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<String?>(
      future: _organizationIdFuture,
      builder: (context, orgSnapshot) {
        if (orgSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (orgSnapshot.hasError || !orgSnapshot.hasData || orgSnapshot.data == null) {
          return const Center(child: Text("Impossible de charger les informations de l'organisation."));
        }

        final organizationId = orgSnapshot.data!;

        return StreamBuilder<List<PurchaseEntity>>(
          stream: _getAllPurchases(organizationId),
          builder: (context, purchaseSnapshot) {
            if (purchaseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (purchaseSnapshot.hasError) {
              return Center(child: Text("Erreur: ${purchaseSnapshot.error}"));
            }
            if (!purchaseSnapshot.hasData || purchaseSnapshot.data!.isEmpty) {
              return const Center(child: Text("Aucun achat trouvé."));
            }

            final allPurchases = purchaseSnapshot.data!;
            final filteredList = _filterPurchases(allPurchases);
            final stats = _computeStats(allPurchases);

            return _buildPurchaseList(filteredList, stats);
          },
        );
      },
    );
  }

  List<PurchaseEntity> _filterPurchases(List<PurchaseEntity> allPurchases) {
    return allPurchases.where((p) {
      final statusMatch = _statusFilter == null || _matchesFilter(p.status, _statusFilter!);
      final dateMatch = _isSameDay(p.createdAt, _selectedDate);
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _DateFilterChip(
              selectedDate: _selectedDate,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = list[i];
                final color = _statusColor(p.status);
                return InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(_statusIcon(p.status), color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p.id} • ${p.supplier.name}', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${_statusLabel(p.status)} • Créé: ${_d(p.createdAt)} • ETA: ${_d(p.eta)} • ${p.warehouse.name}',
                                style: tt.bodySmall?.copyWith(color: cs.outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_money(p.grandTotal), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (p.isLate ? Colors.orange : color).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: p.isLate ? Colors.orange : color),
                              ),
                              child: Text(
                                p.isLate ? 'En retard' : _statusShort(p.status),
                                style: TextStyle(
                                  color: p.isLate ? Colors.orange[700] : color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  
  String _d(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);
  String _money(double v) => NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(v);

  Color _statusColor(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft: return Colors.grey;
      case PurchaseStatus.approved: return Colors.blue;
      case PurchaseStatus.sent: return Colors.indigo;
      case PurchaseStatus.partial: return Colors.orange;
      case PurchaseStatus.received: return Colors.teal;
      case PurchaseStatus.invoiced: return Colors.purple;
      case PurchaseStatus.paid: return Colors.green;
    }
  }

  IconData _statusIcon(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft: return Icons.description_outlined;
      case PurchaseStatus.approved: return Icons.verified_outlined;
      case PurchaseStatus.sent: return Icons.outgoing_mail;
      case PurchaseStatus.partial: return Icons.inventory_outlined;
      case PurchaseStatus.received: return Icons.inventory_2_outlined;
      case PurchaseStatus.invoiced: return Icons.receipt_long_outlined;
      case PurchaseStatus.paid: return Icons.check_circle_outline;
    }
  }

  String _statusLabel(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft: return 'Brouillon';
      case PurchaseStatus.approved: return 'Validée';
      case PurchaseStatus.sent: return 'Envoyée';
      case PurchaseStatus.partial: return 'Réception partielle';
      case PurchaseStatus.received: return 'Réceptionnée';
      case PurchaseStatus.invoiced: return 'Facturée';
      case PurchaseStatus.paid: return 'Payée';
    }
  }

  String _statusShort(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft: return 'Brouillon';
      case PurchaseStatus.approved: return 'Validée';
      case PurchaseStatus.sent: return 'Envoyée';
      case PurchaseStatus.partial: return 'Partielle';
      case PurchaseStatus.received: return 'Reçue';
      case PurchaseStatus.invoiced: return 'Facturée';
      case PurchaseStatus.paid: return 'Payée';
    }
  }

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

// ==== Widgets internes (mis à jour ou nouveaux) ==================================

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
      avatar: Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
      label: Text(label),
      labelStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      backgroundColor: cs.primaryContainer.withOpacity(0.2),
      side: BorderSide(color: cs.primary.withOpacity(0.4)),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primary.withOpacity(0.10),
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
                  style: tt.labelMedium?.copyWith(color: cs.outline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final cs = Theme.of(context).colorScheme;
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
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: current == filter,
              onSelected: (_) => onChanged(filter),
              selectedColor: cs.primary.withOpacity(0.15),
            ),
          );
        }).toList(),
      ),
    );
  }
}
