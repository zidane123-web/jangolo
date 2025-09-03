import 'package:flutter/material.dart';

/// Types publics utilisés par la page dédiée.
enum MoveType { inn, out, adjust }

/// Modèle public minimal pour afficher les mouvements.
class MovementItem {
  final MoveType type;
  final int qty;
  final DateTime date;
  final String reason;
  final String? source;
  final String? user;

  const MovementItem({
    required this.type,
    required this.qty,
    required this.date,
    required this.reason,
    this.source,
    this.user,
  });
}

/// Page dédiée des mouvements d’un article.
/// Par défaut, la liste est filtrée sur "AUJOURD’HUI".
class MovementListScreen extends StatelessWidget {
  final String articleName;
  final String sku;
  final List<MovementItem> allMovements;

  const MovementListScreen({
    super.key,
    required this.articleName,
    required this.sku,
    required this.allMovements,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todays = allMovements.where((m) => _isSameDay(m.date, today)).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // tri décroissant (récent d’abord)

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
            // KPI de la journée
            _KpiRow(sums: sums),
            const SizedBox(height: 12),

            // Liste des mouvements du jour
            if (todays.isEmpty)
              _EmptyToday()
            else
              Expanded(
                child: ListView.separated(
                  itemCount: todays.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _MovementRow(m: todays[index]),
                ),
              ),
          ],
        ),
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

  factory _DaySums.from(List<MovementItem> items) {
    var i = 0, o = 0, adj = 0;
    for (final m in items) {
      switch (m.type) {
        case MoveType.inn:
          i += m.qty;
          break;
        case MoveType.out:
          o += m.qty;
          break;
        case MoveType.adjust:
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
  final MovementItem m;
  const _MovementRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (icon, color) = switch (m.type) {
      MoveType.inn => (Icons.north_east_rounded, Colors.green),
      MoveType.out => (Icons.south_west_rounded, Colors.red),
      MoveType.adjust => (Icons.compare_arrows_rounded, Colors.blueGrey),
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
            backgroundColor: color.withOpacity(0.12),
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
