// lib/features/settings/domain/usecases/update_payment_method.dart

import '../entities/management_entities.dart';
import '../repositories/settings_repository.dart';

class UpdatePaymentMethod {
  final SettingsRepository repository;
  UpdatePaymentMethod(this.repository);

  Future<void> call({
    required String organizationId,
    required PaymentMethod method,
  }) {
    return repository.updatePaymentMethod(
      organizationId: organizationId,
      method: method,
    );
  }
}
