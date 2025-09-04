import 'package:flutter/material.dart';
import 'package:firstapp/src/screens/search_screen.dart';
import 'package:firstapp/src/screens/home_shell.dart';
import 'package:firstapp/src/screens/stock_screen.dart';
import 'package:firstapp/src/screens/notifications_screen.dart';
// ➜ L'IMPORT A ÉTÉ MIS À JOUR ICI
import 'package:firstapp/features/purchases/presentation/screens/purchases_list_screen.dart';

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
    const StockScreen(),
    const PurchasesListScreen(), // ✅ nouvel onglet Achats
    const NotificationsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  // CORRECTION 1 : @Override remplacé par @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: cs.surface,
        // CORRECTION 2 : .withOpacity(0.4) remplacé par .withAlpha(102)
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
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}