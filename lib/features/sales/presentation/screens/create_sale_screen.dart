// lib/features/sales/presentation/screens/create_sale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../domain/entities/sale_entity.dart';
import '../providers/sales_providers.dart';

class CreateSaleScreen extends ConsumerWidget {
  const CreateSaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(createSaleControllerProvider);
    final organizationId = ref.watch(organizationIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle vente')),
      body: Center(
        child: ElevatedButton(
          onPressed: organizationId == null
              ? null
              : () async {
                  final sale = SaleEntity(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    customerId: 'demo',
                    customerName: 'Client démo',
                    createdAt: DateTime.now(),
                    items: const [],
                  );
                  await controller.saveSale(
                      organizationId: organizationId, sale: sale);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          child: const Text('Enregistrer une vente vide'),
        ),
      ),
    );
  }
}
