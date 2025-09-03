import 'package:flutter/material.dart';
import 'package:firstapp/src/screens/settings_screen.dart';
import '../widgets/badge_bell.dart';
import '../tabs/dashboard_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const _AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Jangolo'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: BadgeBell(count: 1),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          indicatorColor: cs.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Announcements'),
            Tab(text: 'Help'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          DashboardTab(),
          _AnnouncementsTab(),
          _HelpTab(),
        ],
      ),
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Announcements (placeholder)'),
    );
  }
}

class _HelpTab extends StatelessWidget {
  const _HelpTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Help (placeholder)'),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text(
              'Jangolo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text('zizakod1.0@gmail.com'),
            currentAccountPicture: CircleAvatar(
              child: Text(
                'Z',
                style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold),
              ),
            ),
            otherAccountsPictures: [
              Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const ListTile(
            leading: Icon(Icons.inventory_2_outlined),
            title: Text('Items'),
            trailing: Icon(Icons.keyboard_arrow_down),
          ),
          const ListTile(
            leading: Icon(Icons.account_balance_outlined),
            title: Text('Banking'),
          ),
          const ListTile(
            leading: Icon(Icons.point_of_sale_outlined),
            title: Text('Sales'),
            trailing: Icon(Icons.keyboard_arrow_down),
          ),
          const ListTile(
            leading: Icon(Icons.shopping_bag_outlined),
            title: Text('Purchases'),
          ),
          const ListTile(
            leading: Icon(Icons.timer_outlined),
            title: Text('Time Tracking'),
            trailing: Icon(Icons.keyboard_arrow_down),
          ),
          const ListTile(
            leading: Icon(Icons.person_pin_outlined),
            title: Text('Accountant'),
            trailing: Icon(Icons.keyboard_arrow_down),
          ),
          const ListTile(
            leading: Icon(Icons.folder_outlined),
            title: Text('Documents'),
          ),
          const ListTile(
            leading: Icon(Icons.bar_chart_outlined),
            title: Text('Reports'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}