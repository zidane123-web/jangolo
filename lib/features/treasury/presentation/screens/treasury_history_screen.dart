// lib/features/treasury/presentation/screens/treasury_history_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';

class TreasuryHistoryScreen extends ConsumerWidget {
  const TreasuryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = FirebaseFirestore.instance;
    final organizationId = ref.watch(organizationIdProvider).value ?? 'demo';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de trésorerie'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('organisations')
            .doc(organizationId)
            .collection('treasury_transactions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune transaction'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final amount = (data['amount'] as num).toDouble();
              final reason = data['type'] ?? '';
              final methodName = data['paymentMethodName'] ?? '';
              return ListTile(
                title: Text(amount.toStringAsFixed(2)),
                subtitle: Text('$reason - $methodName'),
              );
            },
          );
        },
      ),
    );
  }
}
