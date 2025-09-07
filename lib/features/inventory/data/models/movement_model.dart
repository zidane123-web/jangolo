import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/movement_entity.dart';

class MovementModel extends MovementEntity {
  const MovementModel({
    required super.id,
    required super.type,
    required super.qty,
    required super.date,
    required super.reason,
    required super.userId,
    super.sourceDocument,
  });

  factory MovementModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MovementModel(
      id: doc.id,
      type: MovementType.values.firstWhere(
          (e) => e.name == (data['type'] as String? ?? 'inn'),
          orElse: () => MovementType.inn),
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      date: (data['date'] as Timestamp? ?? Timestamp.now()).toDate(),
      reason: data['reason'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      sourceDocument: data['sourceDocument'] as String?,
    );
  }

  factory MovementModel.fromEntity(MovementEntity entity) {
    return MovementModel(
      id: entity.id,
      type: entity.type,
      qty: entity.qty,
      date: entity.date,
      reason: entity.reason,
      userId: entity.userId,
      sourceDocument: entity.sourceDocument,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'qty': qty,
      'date': Timestamp.fromDate(date),
      'reason': reason,
      'userId': userId,
      'sourceDocument': sourceDocument,
    };
  }
}
