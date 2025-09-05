// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ✅ NOUVEL IMPORT
import 'warehouses_list_screen.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profil'),
            subtitle: Text('Modifier vos informations personnelles'),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Sécurité'),
            subtitle: Text('Changer le mot de passe'),
          ),
          const Divider(),

          // ✅ NOUVELLE ENTRÉE POUR LES ENTREPÔTS
          ListTile(
            leading: const Icon(Icons.home_work_outlined),
            title: const Text('Entrepôts'),
            subtitle: const Text('Gérer vos lieux de stockage'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const WarehousesListScreen(),
              ));
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
          ),
          const ListTile(
            leading: Icon(Icons.color_lens_outlined),
            title: Text('Apparence'),
          ),
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Langue'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red.shade700),
            ),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}