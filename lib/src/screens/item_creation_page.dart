// lib/src/screens/item_creation_page.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ItemCreationPage extends StatefulWidget {
  const ItemCreationPage({super.key});

  @override
  State<ItemCreationPage> createState() => _ItemCreationPageState();
}

class _ItemCreationPageState extends State<ItemCreationPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: "1");
  String _unit = "unit";
  bool _variants = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = const Color(0xFF77758D);
    final title = const Color(0xFF9A98B2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with close X
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  _circleIconButton(
                    icon: Icons.close,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashed "Add Photos" box
                    _DashedBox(
                      height: 170,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 44, color: fg.withOpacity(.7)),
                          const SizedBox(height: 8),
                          Text(
                            "Add Photos",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section: Items
                    Text("Items",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: title,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        )),
                    const SizedBox(height: 8),

                    // Enter Item Name
                    TextField(
                      controller: _nameCtrl,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF6F6D86),
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Enter Item Name",
                        hintStyle: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB9B7CC),
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _HairDivider(),

                    // Grid: Quantity • unit  |  Min Level
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: "Quantity • uni…",
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                    controller: _qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.left,
                                    decoration: const InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: "-",
                                    ),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DropdownPill<String>(
                                    value: _unit,
                                    items: const ["unit", "kg", "g", "L", "box"],
                                    onChanged: (v) =>
                                        setState(() => _unit = v ?? "unit"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledField(
                            label: "Min Level",
                            trailing: Icon(Icons.notifications_none,
                                color: fg.withOpacity(.9)),
                            child: Text(
                              "-",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Grid: Price | Total Value
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: "Price",
                            child: Text(
                              "-",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledField(
                            label: "Total Value",
                            child: Text(
                              "-",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    // QR / Barcodes label + help
                    Row(
                      children: [
                        Text(
                          "QR / Barcodes",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.help_outline,
                            size: 20, color: fg.withOpacity(.9)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Buttons
                    _PrimaryActionButton(
                      icon: Icons.qr_code_2_outlined,
                      label: "CREATE CUSTOM LABEL",
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    _SecondaryActionButton(
                      icon: Icons.qr_code_scanner_outlined,
                      label: "LINK QR / BARCODE",
                      onPressed: () {},
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 28, color: fg.withOpacity(.9)),
                    ),
                    const SizedBox(height: 12),
                    const _HairDivider(),
                    const SizedBox(height: 10),

                    // Variants row with toggle
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                "This item has variants",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.help_outline,
                                  size: 20, color: fg.withOpacity(.9)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _variants,
                          onChanged: (v) => setState(() => _variants = v),
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF7B79F3),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFE9E8F1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7E6EE)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF6F6D86)),
      ),
    );
  }
}

// ---------- Small UI pieces ----------

class _HairDivider extends StatelessWidget {
  const _HairDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: const Color(0xFFE7E6EE),
      width: double.infinity,
    );
  }
}


class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  const _LabeledField({
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF9A98B2),
          fontWeight: FontWeight.w700,
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E6EE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: labelStyle)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DropdownPill<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownPill({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E6EE)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    e.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ))
            .toList(),
        underline: const SizedBox.shrink(),
        isDense: true,
        isExpanded: false,
        icon: const Icon(Icons.expand_more),
        onChanged: onChanged,
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFF7F7FB),
          foregroundColor: const Color(0xFF4B4A5F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE7E6EE)),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          side: const BorderSide(color: Color(0xFFE7E6EE)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4B4A5F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// A simple dashed border container without external packages.
class _DashedBox extends StatelessWidget {
  final double height;
  final Widget child;
  const _DashedBox({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: const Color(0xFFCBCADA),
        strokeWidth: 1.5,
        dashLength: 7,
        gapLength: 6,
        radius: 16,
      ),
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Trace the rounded rectangle path and draw dashes along it.
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      double dist = 0;
      final total = metric.length;
      while (dist < total) {
        final next = math.min(dashLength, total - dist);
        final segment = metric.extractPath(dist, dist + next);
        canvas.drawPath(segment, paint);
        dist += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        gapLength != oldDelegate.gapLength ||
        radius != oldDelegate.radius;
  }
}