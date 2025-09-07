enum MovementType { inn, out, adjust }

class MovementEntity {
  final String id;
  final MovementType type;
  final int qty;
  final DateTime date;
  final String reason;
  final String userId;
  final String? sourceDocument;

  const MovementEntity({
    required this.id,
    required this.type,
    required this.qty,
    required this.date,
    required this.reason,
    required this.userId,
    this.sourceDocument,
  });
}
