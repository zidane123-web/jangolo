import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/models/article_detail_data.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/article_entity.dart';
import '../../domain/usecases/add_article.dart';
import '../../domain/usecases/get_articles.dart';
import 'article_detail_screen.dart';
import 'create_article_screen.dart';

class StockScreen extends StatefulWidget {
  final VoidCallback? onViewed;
  const StockScreen({super.key, this.onViewed});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with AutomaticKeepAliveClientMixin {
  late final GetArticles _getArticles;
  late final AddArticle _addArticle;
  Future<String?>? _organizationIdFuture;

  ArticleCategory? _filter;

  @override
  void initState() {
    super.initState();
    final remoteDataSource =
        InventoryRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
    final repository =
        InventoryRepositoryImpl(remoteDataSource: remoteDataSource);
    _getArticles = GetArticles(repository);
    _addArticle = AddArticle(repository); // Initialisation pour la création

    _organizationIdFuture = _getOrganizationId();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onViewed?.call());
  }

  Future<String?> _getOrganizationId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non authentifié.");

    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(user.uid)
        .get();
    return userDoc.data()?['organizationId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
        title: const Text('Stock'),
        actions: [
          IconButton(
              tooltip: 'Recherche',
              onPressed: _onSearchPressed,
              icon: const Icon(Icons.search)),
          IconButton(
              tooltip: 'Scanner',
              onPressed: _onScanPressed,
              icon: const Icon(Icons.qr_code_scanner)),
          IconButton(
              tooltip: 'Ajouter un article',
              onPressed: _onCreateArticle, // Action pour créer un article
              icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _organizationIdFuture,
        builder: (context, orgSnapshot) {
          if (orgSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (orgSnapshot.hasError ||
              !orgSnapshot.hasData ||
              orgSnapshot.data == null) {
            return Center(
                child: Text(
                    "Erreur: Impossible de charger l'organisation. ${orgSnapshot.error}"));
          }
          final organizationId = orgSnapshot.data!;

          return StreamBuilder<List<ArticleEntity>>(
            stream: _getArticles(organizationId),
            builder: (context, articleSnapshot) {
              if (articleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (articleSnapshot.hasError) {
                return Center(
                    child: Text("Erreur: ${articleSnapshot.error}"));
              }
              if (!articleSnapshot.hasData || articleSnapshot.data!.isEmpty) {
                return const Center(
                    child: Text("Aucun article dans l'inventaire."));
              }

              final allArticles = articleSnapshot.data!;
              return _buildContent(allArticles);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(List<ArticleEntity> allArticles) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final list = _filtered(allArticles);
    final statsAll = _statsFor(allArticles);
    final statsFiltered = _statsFor(list);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiRow(
                  tiles: [
                    _KpiTile(
                        label: 'Valeur inventaire (coût)',
                        value: _money(statsAll.valueCost),
                        icon: Icons.inventory_2_outlined),
                    _KpiTile(
                        label: 'Valeur vente',
                        value: _money(statsAll.valueRetail),
                        icon: Icons.sell_outlined),
                    _KpiTile(
                        label: 'Qté totale',
                        value: '${statsAll.totalQty}',
                        icon: Icons.numbers_outlined),
                    _KpiTile(
                        label: 'Stock bas',
                        value: '${statsAll.lowCount}',
                        icon: Icons.warning_amber_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Catégories',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _CategoryChips(
                  current: _filter,
                  onChanged: (c) => setState(() => _filter = c),
                  builderLabel: (c) => _catName(c),
                  builderTrailing: (c) {
                    final s = _statsFor(_byCat(allArticles, c));
                    return Text(_shortMoney(s.valueCost),
                        style: textTheme.bodySmall
                            ?.copyWith(color: cs.outline));
                  },
                ),
                const SizedBox(height: 8),
                if (_filter != null)
                  _FilterSummary(
                    title: 'Résumé ${_catName(_filter!)}',
                    cost: statsFiltered.valueCost,
                    retail: statsFiltered.valueRetail,
                    qty: statsFiltered.totalQty,
                    low: statsFiltered.lowCount,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final it = list[i];
              return Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant.withAlpha(128)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: cs.primary.withAlpha(25),
                    child: Icon(_catIcon(it.category)),
                  ),
                  title: Text(it.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  // ✅ Le sous-titre a été supprimé
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ✅ Le prix affiché est maintenant le CUMP (buyPrice)
                      Text(_money(it.buyPrice),
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      _StockPill(qty: it.totalQuantity),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(_slideFromRight(
                      ArticleDetailScreen(
                        article: ArticleDetailData(
                          name: it.name,
                          sku: it.id,
                          categoryLabel: _catName(it.category),
                          buyPrice: it.buyPrice,
                          sellPrice: it.sellPrice,
                          qty: it.totalQuantity,
                        ),
                      ),
                    ));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onSearchPressed() =>
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Recherche à implémenter')));
  void _onScanPressed() =>
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Scanner à implémenter')));

  Future<void> _onCreateArticle() async {
    final organizationId = await _organizationIdFuture;
    if (organizationId == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateArticleScreen(
          addArticle: _addArticle,
          organizationId: organizationId,
        ),
      ),
    );
  }

  Route _slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final tween = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  _Stats _statsFor(List<ArticleEntity> list) {
    double cost = 0, retail = 0;
    int qty = 0, low = 0;
    for (final a in list) {
      cost += a.buyPrice * a.totalQuantity;
      retail += a.sellPrice * a.totalQuantity;
      qty += a.totalQuantity;
      if (a.totalQuantity <= 20) low += 1; // TODO: use article low-stock threshold
    }
    return _Stats(
        valueCost: cost,
        valueRetail: retail,
        totalQty: qty,
        lowCount: low);
  }

  List<ArticleEntity> _filtered(List<ArticleEntity> all) {
    if (_filter == null) return all;
    return all.where((a) => a.category == _filter).toList();
  }

  List<ArticleEntity> _byCat(List<ArticleEntity> all, ArticleCategory c) =>
      all.where((a) => a.category == c).toList();

  String _money(double v) =>
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)
          .format(v);
          
  String _shortMoney(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} M F';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)} k F';
    return _money(v);
  }

  String _catName(ArticleCategory c) {
    switch (c) {
      case ArticleCategory.phones:
        return 'Téléphones';
      case ArticleCategory.accessories:
        return 'Accessoires';
      case ArticleCategory.tablets:
        return 'Tablettes';
      case ArticleCategory.wearables:
        return 'Wearables';
    }
  }

  IconData _catIcon(ArticleCategory c) {
    switch (c) {
      case ArticleCategory.phones:
        return Icons.smartphone;
      case ArticleCategory.accessories:
        return Icons.cable;
      case ArticleCategory.tablets:
        return Icons.tablet_mac;
      case ArticleCategory.wearables:
        return Icons.watch;
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _Stats {
  final double valueCost, valueRetail;
  final int totalQty, lowCount;
  const _Stats({
    required this.valueCost,
    required this.valueRetail,
    required this.totalQty,
    required this.lowCount,
  });
}

class _StockPill extends StatelessWidget {
  final int qty;
  const _StockPill({required this.qty});
  @override
  Widget build(BuildContext context) {
    final inLow = qty <= 20;
    final color = inLow ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        inLow ? 'Stock bas: $qty' : 'Stock: $qty',
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final List<_KpiTile> tiles;
  const _KpiRow({required this.tiles});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) => tiles[i],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _KpiTile({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cs.outlineVariant.withAlpha(153)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary.withAlpha(25),
              child: Icon(icon, size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelMedium?.copyWith(color: cs.outline)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      maxLines: 1,
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final ArticleCategory? current;
  final ValueChanged<ArticleCategory?> onChanged;
  final String Function(ArticleCategory) builderLabel;
  final Widget Function(ArticleCategory) builderTrailing;
  const _CategoryChips({
    required this.current,
    required this.onChanged,
    required this.builderLabel,
    required this.builderTrailing,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tous'),
              selected: current == null,
              onSelected: (_) => onChanged(null),
              selectedColor: cs.primary.withAlpha(38),
            ),
          ),
          ...ArticleCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(builderLabel(c)),
                      const SizedBox(width: 6),
                      builderTrailing(c),
                    ],
                  ),
                  selected: current == c,
                  onSelected: (_) => onChanged(c),
                  selectedColor: cs.primary.withAlpha(38),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterSummary extends StatelessWidget {
  final String title;
  final double cost, retail;
  final int qty, low;
  const _FilterSummary(
      {required this.title,
      required this.cost,
      required this.retail,
      required this.qty,
      required this.low});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cs.outlineVariant.withAlpha(153)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title — Coût: ${_money(cost)} • Vente: ${_money(retail)} • Qté: $qty • Basse: $low',
              style: tt.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  String _money(double v) => NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(v);
}