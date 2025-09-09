// lib/features/settings/data/models/management_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/management_entities.dart';

// --- Supplier ---
class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    required super.name,
    super.contact,
    super.phone,
  });

  factory SupplierModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupplierModel(
      id: doc.id,
      name: data['name'] ?? '',
      contact: data['contact'] as String?,
      phone: data['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact': contact,
      'phone': phone,
    };
  }
}

// --- Warehouse ---
class WarehouseModel extends Warehouse {
  const WarehouseModel({
    required super.id,
    required super.name,
    super.address,
  });

  factory WarehouseModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WarehouseModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}

// --- PaymentMethod ---
class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    required super.type,
    super.balance = 0.0,
  });

  factory PaymentMethodModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethodModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'cash',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
    };
  }
}