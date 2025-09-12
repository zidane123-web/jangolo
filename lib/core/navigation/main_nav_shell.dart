// lib/core/navigation/main_nav_shell.dart

import 'package:flutter/material.dart';
import 'package:jangolo/src/screens/home_shell.dart';
import 'package:jangolo/features/inventory/presentation/screens/stock_screen.dart';
import 'package:jangolo/src/screens/notifications_screen.dart';
import 'package:jangolo/features/purchases/presentation/screens/purchases_list_screen.dart';
import 'package:jangolo/features/sales/presentation/screens/sales_list_screen.dart';
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
    const StockScreen(),
    const PurchasesListScreen(),
    const SalesListScreen(),
    const TreasuryScreen(),
    const NotificationsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // --- MODIFICATIONS APPLIQUÉES ICI ---
          indicatorColor: Colors.transparent, // Rend l'indicateur invisible
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            // Style pour les libellés (texte sous les icônes)
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black); // Noir si sélectionné
            }
            return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.black); // Noir si non sélectionné
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            // Style pour les icônes
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(
                  color: Colors.black); // Noir si sélectionné
            }
            return const IconThemeData(
                color: Colors.black); // Noir si non sélectionné
          }),
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.white, // Fond blanc
          surfaceTintColor: Colors.white, // Assure un fond blanc pur
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          // --- FIN DES MODIFICATIONS ---
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
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
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Ventes',
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
      ),
    );
  }
}