import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ➜ L'import pointe vers le nouvel emplacement
import 'create_purchase_screen.dart';

// Nouvel enum pour les filtres de statut simplifiés
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
            // --- MODIFICATION ICI ---
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

// ================== Onglet des Commandes =====================================
class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab>
    with AutomaticKeepAliveClientMixin {
  final List<_Purchase> _all = [
    _Purchase(
      id: 'PO-1007',
      supplier: 'Fournisseur Express',
      status: _PStatus.approved,
      createdAt: DateTime.now(), // Achat d'aujourd'hui
      eta: DateTime.now().add(const Duration(days: 5)),
      amount: 150.75,
      warehouse: 'Entrepôt Cotonou',
    ),
    _Purchase(
      id: 'PO-1001',
      supplier: 'TechDistrib SARL',
      status: _PStatus.approved,
      createdAt: DateTime(2025, 8, 21),
      eta: DateTime(2025, 9, 7),
      amount: 4580.00,
      warehouse: 'Entrepôt Cotonou',
    ),
    _Purchase(
      id: 'PO-1002',
      supplier: 'MobilePlus Group',
      status: _PStatus.sent,
      createdAt: DateTime(2025, 8, 28),
      eta: DateTime(2025, 9, 5),
      amount: 12250.50,
      warehouse: 'Magasin Porto-Novo',
    ),
    _Purchase(
      id: 'PO-1003',
      supplier: 'Global Gadgets',
      status: _PStatus.partial,
      createdAt: DateTime(2025, 8, 10),
      eta: DateTime(2025, 8, 30),
      amount: 7899.90,
      warehouse: 'Entrepôt Cotonou',
    ),
    _Purchase(
      id: 'PO-1004',
      supplier: 'TechDistrib SARL',
      status: _PStatus.received,
      createdAt: DateTime(2025, 7, 29),
      eta: DateTime(2025, 8, 8),
      amount: 3150.00,
      warehouse: 'Magasin Porto-Novo',
    ),
    _Purchase(
      id: 'PO-1005',
      supplier: 'Accessories World',
      status: _PStatus.draft,
      createdAt: DateTime(2025, 9, 1),
      eta: DateTime(2025, 9, 15),
      amount: 980.00,
      warehouse: 'Entrepôt Cotonou',
    ),
    _Purchase(
      id: 'PO-1006',
      supplier: 'MobilePlus Group',
      status: _PStatus.paid,
      createdAt: DateTime(2025, 7, 12),
      eta: DateTime(2025, 7, 25),
      amount: 16420.75,
      warehouse: 'Magasin Porto-Novo',
    ),
  ];

  _FilterStatus? _statusFilter; // Utilise le nouvel enum
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Helper pour la nouvelle logique de filtre
  bool _matchesFilter(_PStatus purchaseStatus, _FilterStatus filter) {
    switch (filter) {
      case _FilterStatus.paid:
        return purchaseStatus == _PStatus.paid;
      case _FilterStatus.draft:
        return purchaseStatus == _PStatus.draft;
      case _FilterStatus.unpaid:
        return purchaseStatus != _PStatus.paid &&
            purchaseStatus != _PStatus.draft;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important pour AutomaticKeepAliveClientMixin
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final list = _all.where((p) {
      final statusMatch =
          _statusFilter == null || _matchesFilter(p.status, _statusFilter!);
      final dateMatch = _isSameDay(p.createdAt, _selectedDate);
      return statusMatch && dateMatch;
    }).toList();

    final stats = _computeStats(_all);

    return CustomScrollView(
      slivers: [
        // KPIs
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _KpiGrid(children: [
              _KpiCard(
                  icon: Icons.move_to_inbox_outlined,
                  label: 'À réceptionner',
                  value: '${stats.openCount}'),
              const _KpiCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Dettes fournisseurs',
                  value: '1 450 000 F'),
            ]),
          ),
        ),

        // Filtre par date
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _DateFilterChip(
              selectedDate: _selectedDate,
              onTap: () => _selectDate(context),
            ),
          ),
        ),

        // Filtres par statut (chips)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _StatusChips(
              current: _statusFilter,
              onChanged: (s) => setState(() => _statusFilter = s),
            ),
          ),
        ),

        // Liste
        if (list.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text("Aucun achat trouvé pour cette date."),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = list[i];
                final late = _isLate(p);
                final color = _statusColor(p.status);
                return InkWell(
                  onTap: () => _snack('Détails PO bientôt 😉'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.6)),
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
                              Text('${p.id} • ${p.supplier}',
                                  style: tt.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${_statusLabel(p.status)} • Créé: ${_d(p.createdAt)} • ETA: ${_d(p.eta)} • ${p.warehouse}',
                                style:
                                    tt.bodySmall?.copyWith(color: cs.outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_money(p.amount),
                                style: tt.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (late ? Colors.orange : color)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color: late ? Colors.orange : color),
                              ),
                              child: Text(
                                late ? 'En retard' : _statusShort(p.status),
                                style: TextStyle(
                                  color: late ? Colors.orange[700] : color,
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

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  _PStats _computeStats(List<_Purchase> list) {
    final now = DateTime.now();
    final count = list.length;
    final open = list.where((p) => !_isClosed(p.status)).toList();
    final openCount = open.length;
    final lateCount = open.where((p) => p.eta.isBefore(now)).length;
    final openAmount = open.fold(0.0, (s, p) => s + p.amount);
    return _PStats(
        count: count,
        openCount: openCount,
        lateCount: lateCount,
        openAmount: openAmount);
  }

  bool _isClosed(_PStatus s) => s == _PStatus.paid;
  bool _isLate(_Purchase p) =>
      !_isClosed(p.status) && p.eta.isBefore(DateTime.now());

  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _money(double v) => '${v.toStringAsFixed(2)} F';

  Color _statusColor(_PStatus s) {
    switch (s) {
      case _PStatus.draft:
        return Colors.grey;
      case _PStatus.approved:
        return Colors.blue;
      case _PStatus.sent:
        return Colors.indigo;
      case _PStatus.partial:
        return Colors.orange;
      case _PStatus.received:
        return Colors.teal;
      case _PStatus.invoiced:
        return Colors.purple;
      case _PStatus.paid:
        return Colors.green;
    }
  }

  IconData _statusIcon(_PStatus s) {
    switch (s) {
      case _PStatus.draft:
        return Icons.description_outlined;
      case _PStatus.approved:
        return Icons.verified_outlined;
      case _PStatus.sent:
        return Icons.outgoing_mail;
      case _PStatus.partial:
        return Icons.inventory_outlined;
      case _PStatus.received:
        return Icons.inventory_2_outlined;
      case _PStatus.invoiced:
        return Icons.receipt_long_outlined;
      case _PStatus.paid:
        return Icons.check_circle_outline;
    }
  }

  String _statusLabel(_PStatus s) {
    switch (s) {
      case _PStatus.draft:
        return 'Brouillon';
      case _PStatus.approved:
        return 'Validée';
      case _PStatus.sent:
        return 'Envoyée';
      case _PStatus.partial:
        return 'Réception partielle';
      case _PStatus.received:
        return 'Réceptionnée';
      case _PStatus.invoiced:
        return 'Facturée';
      case _PStatus.paid:
        return 'Payée';
    }
  }

  String _statusShort(_PStatus s) {
    switch (s) {
      case _PStatus.draft:
        return 'Brouillon';
      case _PStatus.approved:
        return 'Validée';
      case _PStatus.sent:
        return 'Envoyée';
      case _PStatus.partial:
        return 'Partielle';
      case _PStatus.received:
        return 'Reçue';
      case _PStatus.invoiced:
        return 'Facturée';
      case _PStatus.paid:
        return 'Payée';
    }
  }

  @override
  bool get wantKeepAlive => true;
}

// ================== Onglet des Statistiques ==================================
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

// ==== Modèles & widgets internes =============================================

class _DateFilterChip extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _DateFilterChip({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _isToday(selectedDate)
        ? "Aujourd'hui"
        : DateFormat('d MMM yyyy', 'fr_FR').format(selectedDate);

    return ActionChip(
      onPressed: onTap,
      avatar: Icon(Icons.calendar_today_outlined,
          size: 18, color: cs.primary),
      label: Text(label),
      labelStyle: TextStyle(
        color: cs.primary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: cs.primaryContainer.withOpacity(0.2),
      side: BorderSide(color: cs.primary.withOpacity(0.4)),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

enum _PStatus { draft, approved, sent, partial, received, invoiced, paid }

class _Purchase {
  final String id;
  final String supplier;
  final _PStatus status;
  final DateTime createdAt;
  final DateTime eta;
  final double amount;
  final String warehouse;

  const _Purchase({
    required this.id,
    required this.supplier,
    required this.status,
    required this.createdAt,
    required this.eta,
    required this.amount,
    required this.warehouse,
  });
}

class _PStats {
  final int count;
  final int openCount;
  final int lateCount;
  final double openAmount;
  const _PStats(
      {required this.count,
      required this.openCount,
      required this.lateCount,
      required this.openAmount});
}

class _KpiGrid extends StatelessWidget {
  final List<Widget> children;
  const _KpiGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, // Forcé à 2 colonnes pour plus d'espace
      childAspectRatio: 2.2, // Ajusté pour donner plus de hauteur
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
            radius: 18, // Taille de l'icône réduite
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
                  maxLines: 1, // Assure que le label ne passe pas à la ligne
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