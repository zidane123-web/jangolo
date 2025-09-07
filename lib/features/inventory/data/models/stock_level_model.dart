import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/stock_level_entity.dart';

class StockLevelModel extends StockLevelEntity {
  const StockLevelModel({
    required super.warehouseId,
    required super.quantity,
  });

  factory StockLevelModel.fromMap(Map<String, dynamic> data) {
    return StockLevelModel(
      warehouseId: data['warehouseId'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  factory StockLevelModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockLevelModel(
      warehouseId: doc.id,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
