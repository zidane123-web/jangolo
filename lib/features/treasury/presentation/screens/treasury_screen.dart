// lib/features/treasury/presentation/screens/treasury_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../settings/domain/entities/management_entities.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../data/models/treasury_transaction_model.dart';
import 'treasury_history_screen.dart';


// --- MODÈLES DE DONNÉES (EXISTANTS ET NOUVEAUX) ---

// Modèle pour représenter le flux de trésorerie
class CashFlow {
  final double cashIn;
  final double cashOut;
  double get net => cashIn - cashOut;

  CashFlow({required this.cashIn, required this.cashOut});
}

// Nouveau: Modèle pour les transactions récentes (données statiques)
class RecentTransaction {
  final String description;
  final double amount;
  final DateTime date;
  final bool isIncome; // Peut être réutilisé pour indiquer le sens du virement

  RecentTransaction({
    required this.description,
    required this.amount,
    required this.date,
    this.isIncome = false,
  });
}

// Nouveau: Modèle pour le suivi budgétaire (données statiques)
class BudgetStatus {
    final String category;
    final double spent;
    final double total;
    double get ratio => (total > 0) ? spent / total : 0;

    BudgetStatus({required this.category, required this.spent, required this.total});
}


// --- PROVIDERS (EXISTANTS ET NOUVEAUX) ---

// Provider pour le Flux de Trésorerie (Cash Flow) - 30 derniers jours
final cashFlowProvider = FutureProvider<CashFlow>((ref) async {
  final organizationId = await ref.watch(organizationIdProvider.future);
  if (organizationId == null) {
    return CashFlow(cashIn: 0, cashOut: 0);
  }

  final firestore = FirebaseFirestore.instance;
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

  final snapshot = await firestore
      .collection('organisations')
      .doc(organizationId)
      .collection('treasury_transactions')
      .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo)
      .get();

  double cashIn = 0;
  double cashOut = 0;

  for (final doc in snapshot.docs) {
    final transaction = TreasuryTransactionModel.fromSnapshot(doc);
    if (transaction.amount > 0) {
      cashIn += transaction.amount;
    } else {
      cashOut += transaction.amount.abs();
    }
  }
  return CashFlow(cashIn: cashIn, cashOut: cashOut);
});

// Provider pour les transactions récentes (modifié pour les virements)
final recentTransactionsProvider = FutureProvider<List<RecentTransaction>>((ref) async {
    // Simule un appel réseau
    await Future.delayed(const Duration(milliseconds: 500));
    return [
        RecentTransaction(description: 'Virement vers Compte Épargne', amount: -150000, date: DateTime.now().subtract(const Duration(days: 1))),
        RecentTransaction(description: 'Virement depuis MTN MoMo', amount: 75000, date: DateTime.now().subtract(const Duration(days: 3)), isIncome: true),
        RecentTransaction(description: 'Virement vers Caisse', amount: -50000, date: DateTime.now().subtract(const Duration(days: 5))),
    ];
});

// Nouveau: Provider pour le suivi budgétaire (statique)
final budgetStatusProvider = FutureProvider<List<BudgetStatus>>((ref) async {
    // Simule un appel réseau
    await Future.delayed(const Duration(milliseconds: 600));
    return [
        BudgetStatus(category: 'Marketing', spent: 150000, total: 200000),
        BudgetStatus(category: 'Fournitures', spent: 85000, total: 75000), // Dépassement
        BudgetStatus(category: 'Salaires', spent: 1200000, total: 1200000),
    ];
});


// --- ÉCRAN PRINCIPAL ---

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  String _money(double v, {String symbol = 'F', bool compact = false}) {
    if (compact && v.abs() >= 1000000) {
        final millions = v / 1000000;
        return '${millions.toStringAsFixed(1)}M $symbol';
    }
    final format = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: symbol,
      decimalDigits: 0,
    );
    return format.format(v);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tableau de Bord', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Historique des transactions',
            icon: const Icon(Icons.history_outlined, color: Colors.black54),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TreasuryHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentMethodsProvider);
          ref.invalidate(cashFlowProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(budgetStatusProvider);
        },
        child: paymentMethodsAsync.when(
          data: (methods) {
            final totalBalance = methods.fold<double>(0, (total, m) => total + m.balance);
            
            // Données statiques pour les KPIs
            const receivables = 450000.0;
            const payables = 180000.0;
            final projectedBalance = totalBalance + receivables - payables;

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
              children: [
                _ProjectedCashFlowCard(
                  currentBalance: totalBalance,
                  receivables: receivables,
                  payables: payables,
                  projectedBalance: projectedBalance,
                  moneyFormatter: _money,
                ),
                const SizedBox(height: 16),
                
                _SectionTitle(title: 'Soldes par Compte'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: methods.length,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, index) {
                      final method = methods[index];
                      return _AccountChip(
                        method: method, 
                        moneyFormatter: _money
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // --- Grille des KPIs supprimée ---

                _SectionTitle(title: 'Flux de Trésorerie (30j)'),
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, _) {
                  final cashFlowAsync = ref.watch(cashFlowProvider);
                  return cashFlowAsync.when(
                    data: (flow) => _CashFlowCard(
                        cashIn: flow.cashIn, 
                        cashOut: flow.cashOut, 
                        moneyFormatter: _money
                    ),
                    loading: () => const _LoadingBox(height: 150),
                    error: (e, _) => _ErrorBox(message: 'Erreur flux: $e'),
                  );
                }),
                const SizedBox(height: 16),
                
                _SectionTitle(title: 'Actions Rapides'),
                const SizedBox(height: 8),
                const _QuickActions(), // <-- Modifiée pour n'afficher que "Virement"
                const SizedBox(height: 16),

                _SectionTitle(title: 'Virements Récents'), // <-- Titre modifié
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, _) {
                    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
                    return recentTransactionsAsync.when(
                        data: (transactions) => _RecentTransactionsList(
                            transactions: transactions,
                            moneyFormatter: _money,
                        ),
                        loading: () => const _LoadingBox(height: 200),
                        error: (e, _) => _ErrorBox(message: 'Erreur virements: $e'),
                    );
                }),
                const SizedBox(height: 16),

                _SectionTitle(title: 'Suivi Budgétaire'),
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, _) {
                    final budgetAsync = ref.watch(budgetStatusProvider);
                    return budgetAsync.when(
                        data: (budgets) => _BudgetStatusList(
                            budgets: budgets, 
                            moneyFormatter: _money
                        ),
                        loading: () => const _LoadingBox(height: 120),
                        error: (e, _) => _ErrorBox(message: 'Erreur budgets: $e'),
                    );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Erreur de chargement des comptes : $e")),
        ),
      ),
    );
  }
}

// --- WIDGETS SPÉCIALISÉS REVISITÉS ET NOUVEAUX ---

class _LoadingBox extends StatelessWidget {
    final double height;
    const _LoadingBox({this.height = 100});

    @override
    Widget build(BuildContext context) {
        return Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)
            ),
            child: const CircularProgressIndicator(),
        );
    }
}

class _ErrorBox extends StatelessWidget {
    final String message;
    const _ErrorBox({required this.message});

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100)
            ),
            child: Text(message, style: TextStyle(color: Colors.red.shade800)),
        );
    }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ProjectedCashFlowCard extends StatelessWidget {
  final double currentBalance;
  final double receivables;
  final double payables;
  final double projectedBalance;
  final String Function(double, {String symbol, bool compact}) moneyFormatter;

  const _ProjectedCashFlowCard({
    required this.currentBalance,
    required this.receivables,
    required this.payables,
    required this.projectedBalance,
    required this.moneyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final totalVisual = currentBalance + receivables + payables;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Trésorerie Prévisionnelle',
              style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (totalVisual > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Expanded(
                    flex: (currentBalance / totalVisual * 100).toInt(),
                    child: Container(height: 10, color: Colors.blue.shade300),
                  ),
                  Expanded(
                    flex: (receivables / totalVisual * 100).toInt(),
                    child: Container(height: 10, color: Colors.green.shade300),
                  ),
                  Expanded(
                    flex: (payables / totalVisual * 100).toInt(),
                    child: Container(height: 10, color: Colors.orange.shade300),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          
          _buildFlowDetailRow(
            'Solde Actuel', 
            currentBalance, 
            Colors.blue.shade300,
          ),
          _buildFlowDetailRow(
            '(+) Créances Clients', 
            receivables, 
            Colors.green.shade300,
            isClickable: true,
            onTap: () {
              // ignore: avoid_print
              print('Navigation vers la liste des créances clients...');
            }
          ),
          _buildFlowDetailRow(
            '(-) Dettes Fournisseurs', 
            payables, 
            Colors.orange.shade300,
            isClickable: true,
            onTap: () {
              // ignore: avoid_print
              print('Navigation vers la liste des dettes fournisseurs...');
            }
          ),
          
          const Divider(height: 24, color: Color(0xFFEEEEEE)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Solde Prévisionnel', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              Text(
                moneyFormatter(projectedBalance),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowDetailRow(String label, double amount, Color color, {bool isClickable = false, VoidCallback? onTap}) {
    final rowContent = Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const Spacer(),
        Text(moneyFormatter(amount, compact: true), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
        if (isClickable) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 14),
          ),
        ]
      ],
    );

    if (isClickable) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: rowContent,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: rowContent,
      );
    }
  }
}

class _AccountChip extends StatelessWidget {
  final PaymentMethod method;
  final String Function(double, {String symbol, bool compact}) moneyFormatter;
  
  const _AccountChip({required this.method, required this.moneyFormatter});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // ignore: avoid_print
        print('${method.name} chip tapped!');
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              method.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            Text(
              moneyFormatter(method.balance, compact: true),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  final double cashIn;
  final double cashOut;
  final String Function(double) moneyFormatter;
  const _CashFlowCard({required this.cashIn, required this.cashOut, required this.moneyFormatter});

  @override
  Widget build(BuildContext context) {
    final netFlow = cashIn - cashOut;
    final totalFlow = cashIn + cashOut;
    final cashInRatio = (totalFlow > 0) ? cashIn / totalFlow : 0.5;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          _CashFlowSimpleChart(cashInRatio: cashInRatio),
          const SizedBox(height: 12),
          _CashFlowRow(
            title: 'Entrées',
            amount: moneyFormatter(cashIn),
            color: Colors.green,
          ),
          const SizedBox(height: 4),
          _CashFlowRow(
            title: 'Sorties',
            amount: moneyFormatter(cashOut),
            color: const Color(0xFFFF7A59),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Solde net', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                moneyFormatter(netFlow),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: netFlow >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _CashFlowSimpleChart extends StatelessWidget {
    final double cashInRatio;
    const _CashFlowSimpleChart({required this.cashInRatio});

    @override
    Widget build(BuildContext context) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
                children: [
                    Expanded(
                        flex: (cashInRatio * 100).toInt(),
                        child: Container(height: 10, color: Colors.green.shade300),
                    ),
                    Expanded(
                        flex: ((1 - cashInRatio) * 100).toInt(),
                        child: Container(height: 10, color: const Color(0xFFFFB5A3)),
                    ),
                ],
            ),
        );
    }
}

class _CashFlowRow extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  const _CashFlowRow({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

// --- WIDGET ACTIONS RAPIDES MODIFIÉ ---
class _QuickActions extends StatelessWidget {
    const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Centré car un seul élément
      children: [
        _ActionButton(icon: Icons.swap_horiz_rounded, label: 'Virement', color: Colors.blueGrey, onTap: () {}),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
    final List<RecentTransaction> transactions;
    final String Function(double, {String symbol, bool compact}) moneyFormatter;

    const _RecentTransactionsList({required this.transactions, required this.moneyFormatter});

    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => Divider(height: 1, indent: 50, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey.withAlpha(26), // Couleur neutre pour virement
                            foregroundColor: Colors.blueGrey,
                            radius: 18,
                            child: const Icon(Icons.swap_horiz_rounded, size: 16),
                        ),
                        title: Text(tx.description, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(DateFormat('d MMM yyyy').format(tx.date), style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                            moneyFormatter(tx.amount),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: tx.isIncome ? Colors.green : Colors.black87
                            ),
                        ),
                    );
                },
            ),
        );
    }
}

class _BudgetStatusList extends StatelessWidget {
    final List<BudgetStatus> budgets;
    final String Function(double, {String symbol, bool compact}) moneyFormatter;

    const _BudgetStatusList({required this.budgets, required this.moneyFormatter});
    
    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
                children: budgets.map((budget) => _BudgetIndicator(
                    budget: budget, 
                    moneyFormatter: moneyFormatter)
                ).toList(),
            ),
        );
    }
}

class _BudgetIndicator extends StatelessWidget {
    final BudgetStatus budget;
    final String Function(double, {String symbol, bool compact}) moneyFormatter;

    const _BudgetIndicator({required this.budget, required this.moneyFormatter});

    Color _getProgressColor(double ratio) {
        if (ratio > 1.0) return Colors.red;
        if (ratio > 0.8) return Colors.orange;
        return Colors.blue;
    }

    @override
    Widget build(BuildContext context) {
        final color = _getProgressColor(budget.ratio);
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
                children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(budget.category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Text(
                                '${moneyFormatter(budget.spent, compact: true)} / ${moneyFormatter(budget.total, compact: true)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                        ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                            value: budget.ratio.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                    ),
                ],
            ),
        );
    }
}