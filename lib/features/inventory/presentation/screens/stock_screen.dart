import 'package:flutter/material.dart';
import '../../data/models/article.dart';
import 'article_detail_screen.dart';

class StockScreen extends StatefulWidget {
  final VoidCallback? onViewed;
  const StockScreen({super.key, this.onViewed});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with AutomaticKeepAliveClientMixin {
  // -----------------------
  // Données fictives
  // -----------------------
  final List<Article> _all = const [
    // ➜ CORRECTION: "cat:" a été remplacé par "category:" partout.
    // Téléphones
    Article(category: ArticleCategory.phones, name: 'iPhone 14 128 Go', sku: 'IP14-128-BLK', buyPrice: 650, sellPrice: 899, qty: 12),
    Article(category: ArticleCategory.phones, name: 'Samsung Galaxy S23', sku: 'SGS23-128', buyPrice: 540, sellPrice: 799, qty: 9),
    Article(category: ArticleCategory.phones, name: 'Xiaomi Redmi Note 13', sku: 'RN13-256', buyPrice: 190, sellPrice: 279, qty: 24),
    Article(category: ArticleCategory.phones, name: 'Tecno Spark 20', sku: 'TSP20-64', buyPrice: 95, sellPrice: 149, qty: 30),

    // Accessoires
    Article(category: ArticleCategory.accessories, name: 'Coque Silicone (iPhone 14)', sku: 'CASE-IP14-SIL', buyPrice: 4.2, sellPrice: 12.9, qty: 140),
    Article(category: ArticleCategory.accessories, name: 'Verre trempé (universel)', sku: 'GLASS-UNI', buyPrice: 1.2, sellPrice: 5.0, qty: 220),
    Article(category: ArticleCategory.accessories, name: 'Chargeur 20W USB-C', sku: 'CHG-20W', buyPrice: 6.8, sellPrice: 19.9, qty: 85),
    Article(category: ArticleCategory.accessories, name: 'Câble USB-C 1m', sku: 'CB-USB-C-1M', buyPrice: 1.9, sellPrice: 7.9, qty: 160),

    // Tablettes
    Article(category: ArticleCategory.tablets, name: 'iPad 10e Gen 64 Go', sku: 'IPAD10-64', buyPrice: 340, sellPrice: 499, qty: 7),
    Article(category: ArticleCategory.tablets, name: 'Samsung Tab A9', sku: 'STABA9-64', buyPrice: 140, sellPrice: 219, qty: 10),

    // Wearables
    Article(category: ArticleCategory.wearables, name: 'Apple Watch SE', sku: 'AW-SE-40', buyPrice: 190, sellPrice: 299, qty: 6),
    Article(category: ArticleCategory.wearables, name: 'Xiaomi Band 8', sku: 'XB8', buyPrice: 21, sellPrice: 39.9, qty: 35),
  ];

  ArticleCategory? _filter; // null = Tous

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onViewed?.call());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final list = _filtered();
    final statsAll = _statsFor(_all);
    final statsFiltered = _statsFor(list);

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
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Scanner',
            onPressed: _onScanPressed,
            icon: const Icon(Icons.qr_code_scanner),
          ),
          IconButton(
            tooltip: 'Statistiques',
            onPressed: () => _openStatsSheet(statsAll),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
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
                        icon: Icons.inventory_2_outlined,
                      ),
                      _KpiTile(
                        label: 'Valeur vente',
                        value: _money(statsAll.valueRetail),
                        icon: Icons.sell_outlined,
                      ),
                      _KpiTile(
                        label: 'Qté totale',
                        value: '${statsAll.totalQty}',
                        icon: Icons.numbers_outlined,
                      ),
                      _KpiTile(
                        label: 'Stock bas',
                        value: '${statsAll.lowCount}',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Catégories', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _CategoryChips(
                    current: _filter,
                    onChanged: (c) => setState(() => _filter = c),
                    builderLabel: (c) => _catName(c),
                    builderTrailing: (c) {
                      final s = _statsFor(_byCat(c));
                      return Text(_shortMoney(s.valueCost), style: textTheme.bodySmall?.copyWith(color: cs.outline));
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: cs.primary.withAlpha(25),
                      child: Icon(_catIcon(it.category)),
                    ),
                    title: Text(
                      it.name,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_catName(it.category)} • SKU: ${it.sku} • Achat: ${_money(it.buyPrice)}',
                        style: textTheme.bodySmall?.copyWith(color: cs.outline),
                      ),
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _money(it.sellPrice),
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        _StockPill(qty: it.qty),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(_slideFromRight(
                        ArticleDetailScreen(
                          article: ArticleDetailData(
                            name: it.name,
                            sku: it.sku,
                            categoryLabel: _catName(it.category),
                            buyPrice: it.buyPrice,
                            sellPrice: it.sellPrice,
                            qty: it.qty,
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
      ),
    );
  }

  void _onSearchPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recherche à implémenter')),
    );
  }

  void _onScanPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner à implémenter')),
    );
  }

  void _openStatsSheet(_Stats statsAll) {
    final byCat = {
      for (final c in ArticleCategory.values) c: _statsFor(_byCat(c)),
    };

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _KpiRow(
                tiles: [
                  _KpiTile(label: 'Inventaire (coût)', value: _money(statsAll.valueCost), icon: Icons.inventory_2_outlined),
                  _KpiTile(label: 'Valeur vente', value: _money(statsAll.valueRetail), icon: Icons.sell_outlined),
                  _KpiTile(label: 'Qté totale', value: '${statsAll.totalQty}', icon: Icons.numbers_outlined),
                  _KpiTile(label: 'Stock bas', value: '${statsAll.lowCount}', icon: Icons.warning_amber_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Par catégorie', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              ...ArticleCategory.values.map((c) {
                final s = byCat[c]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
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
                        child: Icon(_catIcon(c), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_catName(c), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              'Coût: ${_money(s.valueCost)} • Vente: ${_money(s.valueRetail)} • Qté: ${s.totalQty} • Basse: ${s.lowCount}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Route _slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondary, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  _Stats _statsFor(List<Article> list) {
    double cost = 0;
    double retail = 0;
    int qty = 0;
    int low = 0;
    for (final a in list) {
      cost += a.buyPrice * a.qty;
      retail += a.sellPrice * a.qty;
      qty += a.qty;
      if (a.qty <= 20) low += 1;
    }
    return _Stats(valueCost: cost, valueRetail: retail, totalQty: qty, lowCount: low);
  }

  List<Article> _filtered() {
    if (_filter == null) return _all;
    return _all.where((a) => a.category == _filter).toList();
  }

  List<Article> _byCat(ArticleCategory c) => _all.where((a) => a.category == c).toList();

  String _money(double v) => '${v.toStringAsFixed(2)} €';
  String _shortMoney(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)} k€';
    return _money(v);
  }

  String _catName(ArticleCategory c) {
    switch (c) {
      case ArticleCategory.phones: return 'Téléphones';
      case ArticleCategory.accessories: return 'Accessoires';
      case ArticleCategory.tablets: return 'Tablettes';
      case ArticleCategory.wearables: return 'Wearables';
    }
  }

  IconData _catIcon(ArticleCategory c) {
    switch (c) {
      case ArticleCategory.phones: return Icons.smartphone;
      case ArticleCategory.accessories: return Icons.cable;
      case ArticleCategory.tablets: return Icons.tablet_mac;
      case ArticleCategory.wearables: return Icons.watch;
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _Stats {
  final double valueCost;
  final double valueRetail;
  final int totalQty;
  final int lowCount;

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
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final List<_KpiTile> tiles;
  const _KpiRow({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    // ➜ CORRECTION: `textScaleFactor` a été remplacé par `textScaler.scale(1.0)`
    final textScale = mq.textScaler.scale(1.0);

    final crossAxisCount = width < 420 ? 2 : 4;
    double baseRatio = width < 420 ? 1.7 : 2.0;
    final scalePenalty = (textScale - 1.0).clamp(0.0, 0.6);
    final childAspectRatio = (baseRatio - 0.5 * scalePenalty).clamp(1.2, 2.2);

    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) => tiles[i],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelMedium?.copyWith(color: cs.outline),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final chips = <Widget>[];

    chips.add(Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: const Text('Tous'),
        selected: current == null,
        onSelected: (_) => onChanged(null),
        selectedColor: cs.primary.withAlpha(38),
      ),
    ));

    for (final c in ArticleCategory.values) {
      chips.add(Padding(
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
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }
}

class _FilterSummary extends StatelessWidget {
  final String title;
  final double cost;
  final double retail;
  final int qty;
  final int low;

  const _FilterSummary({
    required this.title,
    required this.cost,
    required this.retail,
    required this.qty,
    required this.low,
  });

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

  String _money(double v) => '${v.toStringAsFixed(2)} €';
}