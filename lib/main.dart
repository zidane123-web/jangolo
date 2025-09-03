import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:intl/date_symbol_data_local.dart'; // <-- 1. IMPORT NÉCESSAIRE
import 'firebase_options.dart'; // Import the generated file
// ➜ L'IMPORT EST MIS À JOUR ICI
import 'core/auth/auth_gate.dart';

Future<void> main() async {
  // S'assurer que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- 2. INITIALISER LA LOCALE AVANT TOUT LE RESTE ---
  await initializeDateFormatting('fr_FR', null);

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AfricaPhoneApp());
}

class AfricaPhoneApp extends StatelessWidget {
  const AfricaPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jangolo', // Let's update the app title too!
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        fontFamily: null,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}