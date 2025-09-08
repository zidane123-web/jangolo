import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/purchase_line_entity.dart';
import '../../domain/usecases/get_purchase_details.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final String purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  late final GetPurchaseDetails _getPurchaseDetails;
  Future<PurchaseEntity?>? _purchaseFuture;

  @override
  void initState() {
    super.initState();
    final remoteDataSource =
        PurchaseRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository =
        PurchaseRepositoryImpl(remoteDataSource: remoteDataSource);
    _getPurchaseDetails = GetPurchaseDetails(repository);
    _purchaseFuture = _loadPurchase();
  }

  Future<PurchaseEntity?> _loadPurchase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(user.uid)
        .get();
    final orgId = userDoc.data()?['organizationId'] as String?;
    if (orgId == null) return null;
    return _getPurchaseDetails(
        organizationId: orgId, purchaseId: widget.purchaseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail de l'achat"),
      ),
      body: FutureBuilder<PurchaseEntity?>(
        future: _purchaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: Text("Impossible de charger l'achat."));
          }
          final purchase = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderInfo(purchase: purchase),
                const SizedBox(height: 16),
                _LineItemsList(items: purchase.items),
                const SizedBox(height: 16),
                _FinancialSummary(purchase: purchase),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final PurchaseEntity purchase;
  const _HeaderInfo({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(purchase.supplier.name,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Chip(
              label: Text(_statusLabel(purchase.status)),
              backgroundColor: _statusColor(purchase.status).withOpacity(0.1),
              labelStyle: TextStyle(color: _statusColor(purchase.status)),
              side: BorderSide(color: _statusColor(purchase.status)),
            ),
            const SizedBox(width: 8),
            Text('Créé: ${_d(purchase.createdAt)}'),
          ],
        ),
        const SizedBox(height: 4),
        Text('Entrepôt: ${purchase.warehouse.name}'),
      ],
    );
  }
}

class _LineItemsList extends StatelessWidget {
  final List<PurchaseLineEntity> items;
  const _LineItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Article')),
          DataColumn(label: Text('Qté')),
          DataColumn(label: Text('PU')),
          DataColumn(label: Text('Total')),
        ],
        rows: items
            .map(
              (i) => DataRow(
                cells: [
                  DataCell(Text(i.name)),
                  DataCell(Text(i.qty.toStringAsFixed(0))),
                  DataCell(Text(_money(i.unitPrice))),
                  DataCell(Text(_money(i.lineTotal))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  final PurchaseEntity purchase;
  const _FinancialSummary({required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow('Sous-total', purchase.subTotal),
        _summaryRow('Frais de port', purchase.shippingFees),
        _summaryRow('Autres frais', purchase.otherFees),
        _summaryRow('TVA', purchase.taxTotal),
        const Divider(),
        _summaryRow('Total', purchase.grandTotal, isBold: true),
      ],
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    final style =
        isBold ? const TextStyle(fontWeight: FontWeight.bold) : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(_money(value), style: style),
        ],
      ),
    );
  }
}

String _d(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);
String _money(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
        .format(v);

Color _statusColor(PurchaseStatus s) {
  switch (s) {
    case PurchaseStatus.draft:
      return Colors.grey;
    case PurchaseStatus.approved:
      return Colors.blue;
    case PurchaseStatus.sent:
      return Colors.indigo;
    case PurchaseStatus.partial:
      return Colors.orange;
    case PurchaseStatus.received:
      return Colors.teal;
    case PurchaseStatus.invoiced:
      return Colors.purple;
    case PurchaseStatus.paid:
      return Colors.green;
  }
}

String _statusLabel(PurchaseStatus s) {
  switch (s) {
    case PurchaseStatus.draft:
      return 'Brouillon';
    case PurchaseStatus.approved:
      return 'Validée';
    case PurchaseStatus.sent:
      return 'Envoyée';
    case PurchaseStatus.partial:
      return 'Réception partielle';
    case PurchaseStatus.received:
      return 'Réceptionnée';
    case PurchaseStatus.invoiced:
      return 'Facturée';
    case PurchaseStatus.paid:
      return 'Payée';
  }
}

