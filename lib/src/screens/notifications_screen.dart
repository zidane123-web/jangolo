import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onOpenAll;
  const NotificationsScreen({super.key, this.onOpenAll});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with AutomaticKeepAliveClientMixin {
  final List<_Notif> _items = [
    _Notif(title: 'New follower', body: 'Alex started following you.', time: DateTime.now().subtract(const Duration(minutes: 12))),
    _Notif(title: 'Portfolio up 2.4%', body: 'Your watchlist had a good day.', time: DateTime.now().subtract(const Duration(hours: 2))),
    _Notif(title: 'Price alert • AAPL', body: 'Crossed \$230.00 threshold.', time: DateTime.now().subtract(const Duration(days: 1))),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: false,
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: () {
                widget.onOpenAll?.call();
                setState(() => _items.clear());
              },
              child: const Text('Clear all'),
            ),
          ],
        ),
        if (_items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = _items[i];
                return Dismissible(
                  key: ValueKey(n.title + n.time.toIso8601String()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
                  ),
                  onDismissed: (_) => setState(() => _items.removeAt(i)),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      leading: CircleAvatar(
                        backgroundColor: cs.primary.withOpacity(0.15),
                        child: const Icon(Icons.notifications),
                      ),
                      title: Text(n.title),
                      subtitle: Text(n.body),
                      trailing: Text(_timeAgo(n.time), style: Theme.of(context).textTheme.bodySmall),
                      onTap: () {
                        widget.onOpenAll?.call();
                        // Navigate to a detail page if you want.
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  bool get wantKeepAlive => true;
}

class _Notif {
  final String title;
  final String body;
  final DateTime time;

  _Notif({required this.title, required this.body, required this.time});
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text('You’re all caught up', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'We’ll let you know when something new happens.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
