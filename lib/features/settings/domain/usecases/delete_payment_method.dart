// lib/features/settings/domain/usecases/delete_payment_method.dart

import '../repositories/settings_repository.dart';

class DeletePaymentMethod {
  final SettingsRepository repository;
  DeletePaymentMethod(this.repository);

  Future<void> call({
    required String organizationId,
    required String methodId,
  }) {
    return repository.deletePaymentMethod(
      organizationId: organizationId,
      methodId: methodId,
    );
  }
}
