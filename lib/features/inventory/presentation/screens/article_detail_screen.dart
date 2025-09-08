import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/article_detail_data.dart';
import 'movements_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/movement_entity.dart';
import '../providers/inventory_providers.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleDetailData article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Fiche article'),
        actions: [
          IconButton(
            tooltip: 'Scanner',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner à implémenter')),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
          ),
          IconButton(
            tooltip: 'Modifier',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Édition à implémenter')),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true, // On applique la zone de sécurité uniquement en bas
        top: false,
        child: Column(
          children: [
            // ===== En-tête (reste au-dessus des onglets)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _ArticleHeader(article: widget.article),
            ),

            // ===== Barre d'onglets
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Aperçu'),
                Tab(text: 'Mouvements'),
                Tab(text: 'Analyse'),
              ],
            ),

            // ===== Vues des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- Onglet 1: Aperçu (nettoyé) ---
                  _OverviewTab(article: widget.article),

                  // --- Onglet 2: Mouvements (inchangé) ---
                  _MovementsTab(article: widget.article),

                  // --- Onglet 3: Analyse (contient les détails déplacés) ---
                  _AnalysisTab(article: widget.article),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGETS DÉCOUPÉS POUR PLUS DE CLARTÉ
// =========================================================================

// ===== En-tête de l'article (widget extrait) =====
class _ArticleHeader extends StatelessWidget {
  final ArticleDetailData article;
  const _ArticleHeader({required this.article});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    const lowThreshold = 20;
    final hasLow = article.qty <= lowThreshold;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.primary.withOpacity(0.10),
          child: const Icon(Icons.inventory_2, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.name,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                article.categoryLabel,
                style: tt.bodyMedium?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  _ChipInfo(
                    icon: Icons.inventory_outlined,
                    label: 'Dispo',
                    value: '${article.qty}',
                  ),
                  _ChipInfo(
                    icon: Icons.warning_amber_rounded,
                    label: 'Seuil',
                    value: '$lowThreshold',
                    color: Colors.orange,
                  ),
                  if (hasLow)
                    _ChipBadge(
                      text: 'Stock bas',
                      color: Colors.orange,
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

// ===== Contenu de l'onglet "Aperçu" (essentiel) =====
class _OverviewTab extends StatelessWidget {
  final ArticleDetailData article;
  const _OverviewTab({required this.article});

  String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    // KPI calculés
    final marginUnit = article.sellPrice - article.buyPrice;
    final marginPct =
        article.sellPrice == 0 ? 0 : (marginUnit / article.sellPrice) * 100;
    final potentialMargin = marginUnit * article.qty;
    final inventoryCost = article.buyPrice * article.qty;
    final inventoryRetail = article.sellPrice * article.qty;
    const lowThreshold = 20;
    final hasLow = article.qty <= lowThreshold;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ===== KPI Prix & Marges
        const _SectionTitle(title: 'Prix & marges'),
        const SizedBox(height: 8),
        _KpiGrid(children: [
          _KpiCard(
              icon: Icons.shopping_cart_outlined,
              label: 'Coût moyen',
              value: _money(article.buyPrice)),
          _KpiCard(
              icon: Icons.sell_outlined,
              label: 'Prix vente',
              value: _money(article.sellPrice)),
          _KpiCard(
              icon: Icons.calculate_outlined,
              label: 'Marge /u',
              value:
                  '${_money(marginUnit)}  (${marginPct.toStringAsFixed(1)}%)'),
          _KpiCard(
              icon: Icons.payments_outlined,
              label: 'Marge potentielle',
              value: _money(potentialMargin)),
        ]),
        const SizedBox(height: 12),

        // ===== Inventaire
        const _SectionTitle(title: 'Inventaire'),
        const SizedBox(height: 8),
        _TileBox(
          leadingIcon: Icons.inventory_2_outlined,
          title: 'Valeur inventaire (coût)',
          subtitle: _money(inventoryCost),
        ),
        const SizedBox(height: 8),
        _TileBox(
          leadingIcon: Icons.storefront_outlined,
          title: 'Valeur vente potentielle',
          subtitle: _money(inventoryRetail),
        ),
        const SizedBox(height: 12),

        // ===== Alertes
        const _SectionTitle(title: 'Alertes'),
        const SizedBox(height: 8),
        if (hasLow)
          _AlertLine(
            icon: Icons.warning_amber_rounded,
            text:
                'Stock bas : ${article.qty} (seuil $lowThreshold). Pense à réapprovisionner.',
            color: Colors.orange,
          )
        else
          const _AlertLine(
            icon: Icons.check_circle_outline,
            text: 'Stock normal.',
            color: Colors.green,
          ),
        const SizedBox(height: 20),

        // ===== Actions rapides
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ajustement stock à implémenter')),
                  );
                },
                icon: const Icon(Icons.tune),
                label: const Text('Ajuster stock'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Réappro à implémenter')),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Réappro'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===== Contenu de l'onglet "Mouvements" =====
class _MovementsTab extends ConsumerWidget {
  final ArticleDetailData article;
  const _MovementsTab({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsStreamProvider(article.sku));

    return movementsAsync.when(
      data: (movements) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(child: _SectionTitle(title: 'Derniers Mouvements')),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MovementListScreen(
                          articleName: article.name,
                          sku: article.sku,
                          articleId: article.sku,
                        ),
                      ),
                    );
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (movements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('Aucun mouvement enregistré.')),
              )
            else
              ...movements.map((m) => _MovementTile(m: m)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
    );
  }
}

// ===== Contenu de l'onglet "Analyse" =====
class _AnalysisTab extends StatelessWidget {
  final ArticleDetailData article;
  const _AnalysisTab({required this.article});

  String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    final sales30d = _fakeSales30d();
    final supplier = _fakeSupplier();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ===== Ventes récentes (30j)
        const _SectionTitle(title: 'Ventes (30 jours)'),
        const SizedBox(height: 8),
        _SalesMiniChartPlaceholder(
            total: sales30d.totalQty, revenue: sales30d.revenue),
        const SizedBox(height: 12),

        // ===== Achats & fournisseur
        const _SectionTitle(title: 'Achats & fournisseur'),
        const SizedBox(height: 8),
        _TileBox(
          leadingIcon: Icons.local_shipping_outlined,
          title: 'Fournisseur principal',
          subtitle:
              '${supplier.name} • Délai: ${supplier.leadDays} j • MOQ: ${supplier.moq}',
        ),
        const SizedBox(height: 8),
        _TileBox(
          leadingIcon: Icons.assignment_outlined,
          title: 'Coût moyen pondéré',
          subtitle: _money(supplier.weightedCost),
        ),
        const SizedBox(height: 8),
        _TileBox(
          leadingIcon: Icons.shopping_bag_outlined,
          title: 'Commande en cours',
          subtitle: supplier.hasOpenPo
              ? 'Qté: ${supplier.openPoQty} • ETA: ${supplier.eta}'
              : 'Aucune',
        ),
        const SizedBox(height: 12),

        // ===== Notes internes
        const _SectionTitle(title: 'Notes internes'),
        const SizedBox(height: 8),
        const _NotesBox(
          notes:
              '• Mettre en avant en vitrine le weekend.\n• Vérifier la compatibilité des coques associées.\n• Surveiller le délai fournisseur (tendance à glisser de 2–3 jours).',
        ),
      ],
    );
  }

  // --- Données fictives pour l'onglet analyse ---
  _SalesSummary _fakeSales30d() {
    final qty = 27;
    final revenue = qty * article.sellPrice;
    return _SalesSummary(totalQty: qty, revenue: revenue);
  }

  _SupplierInfo _fakeSupplier() => _SupplierInfo(
        name: 'TechDistrib SARL',
        leadDays: 5,
        moq: 10,
        weightedCost: article.buyPrice * 0.98,
        hasOpenPo: true,
        openPoQty: 15,
        eta: 'J+4',
      );
}


// ===== Petits widgets de présentation (inchangés) =====
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final List<Widget> children;
  const _KpiGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cross = width < 420 ? 2 : 4;
    return GridView.count(
      crossAxisCount: cross,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
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
  const _KpiCard(
      {required this.icon, required this.label, required this.value});

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
            backgroundColor: cs.primary.withAlpha(25),
            child: Icon(icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.labelMedium?.copyWith(color: cs.outline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _TileBox extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  const _TileBox(
      {required this.leadingIcon,
      required this.title,
      required this.subtitle});

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
            backgroundColor: cs.primary.withAlpha(25),
            child: Icon(leadingIcon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ]),
          ),
        ],
      ),
    );
  }
}

class _SalesMiniChartPlaceholder extends StatelessWidget {
  final int total;
  final double revenue;
  const _SalesMiniChartPlaceholder({required this.total, required this.revenue});

    String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total vendus (30j): $total\nChiffre d’affaires: ${_money(revenue)}',
              style: tt.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 110,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('Graph 30j',
                style: tt.labelSmall?.copyWith(color: cs.primary)),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final MovementEntity m;
  const _MovementTile({required this.m});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color) = switch (m.type) {
      MovementType.inn => (Icons.north_east_rounded, Colors.green),
      MovementType.out => (Icons.south_west_rounded, Colors.red),
      MovementType.adjust => (Icons.compare_arrows_rounded, Colors.blueGrey),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${m.qty > 0 ? '+' : ''}${m.qty} • ${_fmtDate(m.date)}'),
              const SizedBox(height: 2),
              Text(m.reason,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline)),
            ]),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _SalesSummary {
  final int totalQty;
  final double revenue;
  const _SalesSummary({required this.totalQty, required this.revenue});
}

class _SupplierInfo {
  final String name;
  final int leadDays;
  final int moq;
  final double weightedCost;
  final bool hasOpenPo;
  final int openPoQty;
  final String eta;

  const _SupplierInfo({
    required this.name,
    required this.leadDays,
    required this.moq,
    required this.weightedCost,
    required this.hasOpenPo,
    required this.openPoQty,
    required this.eta,
  });
}

// ===== Petits badges / utilitaires
class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _ChipInfo(
      {required this.icon,
      required this.label,
      required this.value,
      this.color});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text('$label: $value',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: c)),
        ],
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _ChipBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(text,
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}

class _AlertLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _AlertLine(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _NotesBox extends StatelessWidget {
  final String notes;
  const _NotesBox({required this.notes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        notes,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}