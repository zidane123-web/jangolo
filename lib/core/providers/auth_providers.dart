import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fournit l'instance de [FirebaseAuth].
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Fournit l'état d'authentification de l'utilisateur en temps réel.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Fournit l'ID de l'organisation de l'utilisateur connecté.
/// Toute la logique de récupération de l'ID est centralisée ici.
final organizationIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return null;
  }
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(user.uid)
        .get();
    return userDoc.data()?['organizationId'] as String?;
  } catch (e) {
    // Optionnel : log de l'erreur
    return null;
  }
});
