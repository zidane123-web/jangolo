import 'package:flutter/material.dart';

class MiniBarStrip extends StatelessWidget {
  const MiniBarStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // simple colored bars to mimic the "Top Expenses" tiny chart
    final bars = List.generate(
      8,
      (i) => Expanded(
        child: Container(
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: .25 + (i % 3) * .1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );

    return Row(children: bars);
  }
}
