// lib/features/sales/presentation/screens/sales_list_screen.dart

import 'package:flutter/material.dart';

class SalesListScreen extends StatelessWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventes')),
      body: const Center(child: Text('Liste des ventes')),
    );
  }
}
