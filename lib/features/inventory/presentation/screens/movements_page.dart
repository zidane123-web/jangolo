import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/movement_entity.dart';
import '../providers/inventory_providers.dart';

class MovementListScreen extends ConsumerWidget {
  final String articleName;
  final String sku;
  final String articleId;

  const MovementListScreen({
    super.key,
    required this.articleName,
    required this.sku,
    required this.articleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsStreamProvider(articleId));

    return movementsAsync.when(
      data: (allMovements) {
        final today = DateTime.now();
        final todays = allMovements
            .where((m) => _isSameDay(m.date, today))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final sums = _DaySums.from(todays);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mouvements'),
                Text(
                  '$articleName • SKU: $sku',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _KpiRow(sums: sums),
                const SizedBox(height: 12),
                if (todays.isEmpty)
                  _EmptyToday()
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: todays.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _MovementRow(m: todays[index]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Mouvements')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Mouvements')),
        body: Center(child: Text('Erreur: $err')),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DaySums {
  final int inn;
  final int out;
  final int adjust;
  int get net => inn - out + adjust;

  _DaySums({required this.inn, required this.out, required this.adjust});

  factory _DaySums.from(List<MovementEntity> items) {
    var i = 0, o = 0, adj = 0;
    for (final m in items) {
      switch (m.type) {
        case MovementType.inn:
          i += m.qty;
          break;
        case MovementType.out:
          o += m.qty;
          break;
        case MovementType.adjust:
          adj += m.qty;
          break;
      }
    }
    return _DaySums(inn: i, out: o, adjust: adj);
  }
}

class _KpiRow extends StatelessWidget {
  final _DaySums sums;
  const _KpiRow({required this.sums});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardDeco = BoxDecoration(
      color: Colors.white,
      border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      borderRadius: BorderRadius.circular(12),
    );

    Widget kpi(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: cardDeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.outline)),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        kpi('Entrées (u)', '${sums.inn}'),
        const SizedBox(width: 8),
        kpi('Sorties (u)', '${sums.out}'),
        const SizedBox(width: 8),
        kpi('Ajustements (u)', '${sums.adjust}'),
        const SizedBox(width: 8),
        kpi('Variation nette', '${sums.net >= 0 ? '+' : ''}${sums.net}'),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  final MovementEntity m;
  const _MovementRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (icon, color) = switch (m.type) {
      MovementType.inn => (Icons.north_east_rounded, Colors.green),
      MovementType.out => (Icons.south_west_rounded, Colors.red),
      MovementType.adjust => (Icons.compare_arrows_rounded, Colors.blueGrey),
    };

    String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.qty > 0 ? '+' : ''}${m.qty} • ${hhmm(m.date)}'),
              const SizedBox(height: 2),
              Text(
                m.reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: cs.outline),
            const SizedBox(height: 8),
            Text('Aucun mouvement aujourd’hui.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline)),
          ],
        ),
      ),
    );
  }
}