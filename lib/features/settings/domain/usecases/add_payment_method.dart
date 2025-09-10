// lib/features/settings/domain/usecases/add_payment_method.dart

import '../entities/management_entities.dart';
import '../repositories/settings_repository.dart';

class AddPaymentMethod {
  final SettingsRepository repository;
  AddPaymentMethod(this.repository);

  Future<PaymentMethod> call({
    required String organizationId,
    required String name,
    required String type,
    required double initialBalance,
  }) {
    return repository.addPaymentMethod(
      organizationId: organizationId,
      name: name,
      type: type,
      initialBalance: initialBalance,
    );
  }
}
