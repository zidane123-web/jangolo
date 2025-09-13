// lib/features/sales/presentation/screens/sale_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/sale_entity.dart';
import '../providers/sales_providers.dart';

class SaleDetailScreen extends ConsumerStatefulWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen>
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
    final saleAsync = ref.watch(saleDetailProvider(widget.saleId));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Détail de la vente"),
        backgroundColor: Colors.white,
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
      ),
      body: saleAsync.when(
        data: (sale) {
          if (sale == null) {
            return const Center(child: Text("Vente introuvable."));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _SaleHeader(sale: sale),
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
                    _OverviewTab(sale: sale),
                    _PaymentsTab(sale: sale),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
      ),
    );
  }
}

// ================= WIDGETS DÉCOUPÉS =================

class _SaleHeader extends StatelessWidget {
  final SaleEntity sale;
  const _SaleHeader({required this.sale});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFFE0F2FE),
          foregroundColor: Color(0xFF0C529D),
          child: Icon(Icons.person_outline, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sale.customerName ?? 'Client',
                  style:
                      tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(_d(sale.createdAt),
                      style: tt.bodySmall
                          ?.copyWith(color: Colors.grey.shade700)),
                ],
              ),
              const SizedBox(height: 8),
              _StatusBadge(status: sale.paymentStatus),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final SaleEntity sale;
  const _OverviewTab({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = sale.items;

    final subTotal = items.fold<double>(0, (s, i) => s + i.lineSubtotal);
    final taxTotal = items.fold<double>(0, (s, i) => s + i.lineTax);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _SectionTitle(title: 'Articles vendus'),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text("Aucun article dans cette vente."),
          ))
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade100,
                      child: Text(item.quantity.toStringAsFixed(0))),
                  title: Text(item.name ?? 'Article',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Text(_money(item.lineTotal),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        const Divider(height: 32),
        const _SectionTitle(title: 'Résumé Financier'),
        const SizedBox(height: 12),
        _FinancialSummaryLine(label: 'Sous-total', value: _money(subTotal)),
        _FinancialSummaryLine(
            label: 'Remise globale', value: _money(-sale.globalDiscount)),
        _FinancialSummaryLine(
            label: 'Frais de livraison', value: _money(sale.shippingFees)),
        _FinancialSummaryLine(label: 'TVA', value: _money(taxTotal)),
        const SizedBox(height: 8),
        _FinancialSummaryLine(
            label: 'Total Général',
            value: _money(sale.grandTotal),
            isBold: true),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final SaleEntity sale;
  const _PaymentsTab({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payments = sale.payments;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _SectionTitle(title: 'Résumé des Paiements'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _FinancialSummaryLine(
                    label: 'Total Vente', value: _money(sale.grandTotal)),
                const SizedBox(height: 8),
                _FinancialSummaryLine(
                    label: 'Total Payé', value: _money(sale.totalPaid)),
                const Divider(height: 20),
                _FinancialSummaryLine(
                  label: 'Solde Dû',
                  value: _money(sale.balanceDue),
                  isBold: true,
                  color: sale.balanceDue > 0.01
                      ? Colors.red.shade700
                      : Colors.green.shade800,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 32),
        const _SectionTitle(title: 'Historique des Encaissements'),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text("Aucun paiement enregistré."),
          ))
        else
          ...payments.map((p) => _PaymentTile(payment: p)),
      ],
    );
  }
}

// ================= PETITS WIDGETS DE PRÉSENTATION =================

class _PaymentTile extends StatelessWidget {
  final PaymentEntity payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0FEEF),
          foregroundColor: Color(0xFF056441),
          child: Icon(Icons.check),
        ),
        title: Text(_money(payment.amount),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Via ${payment.paymentMethod.name}'),
        trailing: Text(_d(payment.date)),
      ),
    );
  }
}

class _FinancialSummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _FinancialSummaryLine({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700)),
          Text(
            value,
            style: (isBold
                    ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                    : textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600))
                ?.copyWith(color: color),
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
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _StatusBadge extends StatelessWidget {
  final PaymentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ================= HELPERS =================

String _d(DateTime d) => DateFormat('dd/MM/yy', 'fr_FR').format(d);
String _money(double v) => NumberFormat.currency(
        locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
    .format(v);

(String, Color) _statusInfo(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.unpaid:
      return ('Non Payé', Colors.red.shade700);
    case PaymentStatus.partial:
      return ('Partiel', Colors.orange.shade800);
    case PaymentStatus.paid:
      return ('Payé', Colors.green.shade800);
  }
}

