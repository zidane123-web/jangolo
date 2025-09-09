import 'package:flutter/material.dart';
import 'package:jangolo/src/screens/search_screen.dart';
import 'package:jangolo/src/screens/home_shell.dart';
// ✅ L'IMPORT A ÉTÉ MIS À JOUR ICI
import 'package:jangolo/features/inventory/presentation/screens/stock_screen.dart';
import 'package:jangolo/src/screens/notifications_screen.dart';
import 'package:jangolo/features/purchases/presentation/screens/purchases_list_screen.dart';
import 'package:jangolo/features/treasury/presentation/screens/treasury_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = <Widget>[
    const HomeShell(),
    const SearchScreen(),
    const StockScreen(), // ✅ Maintenant, ceci utilise la bonne version de l'écran
    const PurchasesListScreen(),
    const TreasuryScreen(),
    const NotificationsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer.withAlpha(102),
        surfaceTintColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Achats',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Trésorerie',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}