// Types publics utilisés par la page des mouvements.
enum MoveType { inn, out, adjust }

// Modèle public minimal pour afficher un mouvement.
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