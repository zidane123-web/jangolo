import 'package:flutter/material.dart';
import '../widgets/mini_bar_strip.dart';
import '../widgets/section_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/tiny_line_chart.dart';
import '../screens/item_creation_page.dart'; // <-- CHANGEMENT DU NOM DE FICHIER

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // QUICK CREATE
        SectionCard(
          title: 'Quick Create',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickBtn(
                icon: Icons.point_of_sale,
                label: 'Vente',
                color: Colors.blue,
                onPressed: () {
                  // AJOUTER LA LOGIQUE DE NAVIGATION ICI
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ItemCreationPage(),
                  ));
                },
              ),
              const _QuickBtn(
                icon: Icons.shopping_bag,
                label: 'Achat',
                color: Colors.green,
              ),
              const _QuickBtn(
                icon: Icons.money_off,
                label: 'Dépense',
                color: Colors.orange,
              ),
              const _QuickBtn(
                icon: Icons.inventory,
                label: 'Stock',
                color: Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CASH FLOW + chart
        SectionCard(
          title: 'Cash Flow',
          trailing: _TimeRangeDropdown(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const TinyLineChart(height: 140),
              const SizedBox(height: 16),
              _cashRow('Cash as on 01 Jan 2025', 'XOF0', cs),
              const SizedBox(height: 8),
              _cashRow('+ Incoming', 'XOF0', cs, color: Colors.green),
              const SizedBox(height: 2),
              _cashRow('- Outgoing', 'XOF0', cs, color: Colors.red),
              const SizedBox(height: 8),
              _cashRow('= Cash as on 31 Dec 2025', 'XOF0', cs, isBold: true),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // TIMER card
        SectionCard(
          title: 'Project Timer',
          child: _TimerBlock(),
        ),

        const SizedBox(height: 16),

        // TOTALS + OVERDUE
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Total Receivables',
                value: 'XOF52,000',
                tint: Color(0xFFBBDEFB),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Total Payables',
                value: 'XOF0',
                tint: Color(0xFFE3F2FD),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Overdue Invoices',
                value: '1',
                tint: Color(0xFFFFEBEE),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Overdue Bills',
                value: '0',
                tint: Color(0xFFF1F8E9),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // TOP EXPENSES
        SectionCard(
          title: 'Top Expenses',
          trailing: _TimeRangeDropdown(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MiniBarStrip(),
              SizedBox(height: 12),
              Text(
                "You haven't created any expenses for the selected period.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cashRow(String label, String value, ColorScheme cs,
      {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? cs.onSurface,
            )),
        Text(value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? cs.onSurface,
            )),
      ],
    );
  }
}

class _TimerBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '00:00',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Start Project Timer'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Log Time'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Start Timer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed, // AJOUTER LE PARAMÈTRE onPressed
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed; // AJOUTER CETTE PROPRIÉTÉ

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed, // UTILISER CETTE PROPRIÉTÉ
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

class _TimeRangeDropdown extends StatefulWidget {
  @override
  State<_TimeRangeDropdown> createState() => _TimeRangeDropdownState();
}

class _TimeRangeDropdownState extends State<_TimeRangeDropdown> {
  String value = 'This Fiscal Year';
  final items = const [
    'This Fiscal Year',
    'This Year',
    'Last 12 Months',
    'Last 30 Days'
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => value = v ?? value),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}