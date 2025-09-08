// lib/features/purchases/presentation/screens/purchase_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/purchase_entity.dart';
import '../providers/purchases_providers.dart';

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  final String purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  ConsumerState<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen>
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
    final purchaseAsync = ref.watch(purchaseDetailProvider(widget.purchaseId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Détail de l'achat"),
        backgroundColor: Colors.white,
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
      ),
      body: purchaseAsync.when(
        data: (purchase) {
          if (purchase == null) {
            return const Center(
                child: Text("Impossible de charger les détails de l'achat."));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _PurchaseHeader(purchase: purchase),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Aperçu'),
                  Tab(text: 'Paiements'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(purchase: purchase),
                    _PaymentsTab(purchase: purchase),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text("Impossible de charger les détails de l'achat.")),
      ),
    );
  }
}

// =========================================================================
// WIDGETS DÉCOUPÉS
// =========================================================================

// ✅ --- MODIFICATION MAJEURE ---
// L'en-tête inclut maintenant les informations de date, ETA et entrepôt.
class _PurchaseHeader extends StatelessWidget {
  final PurchaseEntity purchase;
  const _PurchaseHeader({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.primary.withOpacity(0.10),
          child: const Icon(Icons.receipt_long_outlined, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(purchase.supplier.name,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              // --- INFOS COMPACTES AJOUTÉES ICI ---
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text('Cmd: ${_d(purchase.createdAt)}', style: tt.bodySmall?.copyWith(color: cs.outline)),
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  Icon(Icons.event_available_outlined, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text('ETA: ${_d(purchase.eta)}', style: tt.bodySmall?.copyWith(color: cs.outline)),
                ],
              ),
               const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.home_work_outlined, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      purchase.warehouse.name,
                      style: tt.bodySmall?.copyWith(color: cs.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // --- FIN DES INFOS COMPACTES ---
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  _StatusBadge(status: purchase.status),
                  _ChipInfo(
                    icon: Icons.paid_outlined,
                    label: 'Solde dû',
                    value: _money(purchase.balanceDue),
                    color: purchase.balanceDue > 0.01 ? Colors.orange : Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ✅ --- MODIFICATION ---
// La section "Informations" a été retirée d'ici.
class _OverviewTab extends StatelessWidget {
  final PurchaseEntity purchase;
  const _OverviewTab({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = purchase.items;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // --- 1. Articles commandés ---
        const _SectionTitle(title: 'Articles commandés'),
        const SizedBox(height: 12),

        if (items.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text("Aucun article dans cette commande."),
          ))
        else
          ListView.separated(
            shrinkWrap: true,
            primary: false,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(128)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(child: Text(item.qty.toStringAsFixed(0))),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('PU: ${_money(item.unitPrice)} + Transport: ${_money(item.allocatedShipping ?? 0)}'),
                  trailing: Text(_money(item.lineTotal), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        
        const Divider(height: 32),

        // --- 2. Résumé financier ---
        const _SectionTitle(title: 'Résumé Financier'),
        const SizedBox(height: 12),
        _FinancialSummaryLine(label: 'Sous-total', value: _money(purchase.subTotal)),
        _FinancialSummaryLine(label: 'Frais de port', value: _money(purchase.shippingFees)),
        _FinancialSummaryLine(label: 'TVA', value: _money(purchase.taxTotal)),
        const SizedBox(height: 8),
        _FinancialSummaryLine(label: 'Total Général', value: _money(purchase.grandTotal), isBold: true),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final PurchaseEntity purchase;
  const _PaymentsTab({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payments = purchase.payments;
    if (payments.isEmpty) {
      return const Center(child: Text("Aucun paiement enregistré."));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(128)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.check)),
            title: Text(_money(payment.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Via ${payment.paymentMethod.name}'),
            trailing: Text(_d(payment.date)),
          ),
        );
      },
    );
  }
}


// ===== Petits widgets de présentation =====

class _FinancialSummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _FinancialSummaryLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyLarge),
          Text(
            value,
            style: isBold 
              ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _ChipInfo({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withAlpha(89)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text('$label: $value', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PurchaseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(_statusLabel(status), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// =========================================================================
// HELPERS
// =========================================================================

String _d(DateTime d) => DateFormat('dd/MM/yy', 'fr_FR').format(d); // Date format shortened
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