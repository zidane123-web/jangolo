// lib/features/sales/data/models/client_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.name,
    super.phone,
    super.address,
  });

  factory ClientModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      id: doc.id,
      name: data['name'] as String? ?? 'N/A',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
