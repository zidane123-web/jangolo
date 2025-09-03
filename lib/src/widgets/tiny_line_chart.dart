import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A lightweight line chart placeholder (no packages)
class TinyLineChart extends StatelessWidget {
  const TinyLineChart({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: CustomPaint(
        painter: _ChartPainter(color: cs.primary),
        size: Size.infinite,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // grid lines
    final grid = Paint()
      ..color = color.withValues(alpha: .15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // fake series
    final path = Path();
    final rnd = math.Random(3);
    final points = List.generate(12, (i) {
      final x = size.width * i / 11;
      final y = size.height * (0.2 + 0.6 * rnd.nextDouble());
      return Offset(x, y);
    });

    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => false;
}
