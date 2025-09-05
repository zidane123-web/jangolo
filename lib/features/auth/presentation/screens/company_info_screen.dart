import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ➜ L'IMPORT VERS LE SHELL DE NAVIGATION EST AJOUTÉ ICI
import '../../../../core/navigation/main_nav_shell.dart';
import '../../../../shared/widgets/outlined_floating_field.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  final _companyNameCtrl = TextEditingController();
  final _websiteUrlCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  Future<void> _finishSignUp() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _submitting = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final user = userCredential.user;
      if (user == null) {
        // Si l'utilisateur est null, on arrête et on gère l'erreur.
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La création de l\'utilisateur a échoué.'), backgroundColor: Colors.redAccent),
          );
        }
        setState(() => _submitting = false);
        return;
      }


      final batch = FirebaseFirestore.instance.batch();

      final orgRef = FirebaseFirestore.instance.collection('organisations').doc();
      final organizationId = orgRef.id;

      batch.set(orgRef, {
        'name': _companyNameCtrl.text.trim(),
        'website': _websiteUrlCtrl.text.trim(),
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final userRef =
          FirebaseFirestore.instance.collection('utilisateurs').doc(user.uid);
      batch.set(userRef, {
        'firstName': widget.firstName,
        'lastName': widget.lastName,
        'email': widget.email,
        'organizationId': organizationId,
        'role': 'owner',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // ✅ --- CORRECTION AJOUTÉE ICI ---
      // Une fois que tout est sauvegardé, on navigue vers l'écran principal.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavShell()),
          (Route<dynamic> route) => false,
        );
      }
      // --- FIN DE LA CORRECTION ---

    } on FirebaseAuthException catch (e) {
      String message = 'Une erreur est survenue. Réessayez.';
      if (e.code == 'weak-password') {
        message = 'Le mot de passe fourni est trop faible.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Un compte existe déjà pour cet e-mail.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    // On ne remet _submitting à false que si une erreur survient,
    // car en cas de succès, l'écran est détruit par la navigation.
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _websiteUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Étape 4 sur 4',
                      style: t.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Parlons de votre entreprise",
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedFloatingField(
                    controller: _websiteUrlCtrl,
                    label: 'URL du site web (facultatif)',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  OutlinedFloatingField(
                    controller: _companyNameCtrl,
                    label: "Nom de l'entreprise",
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Le nom de l\'entreprise est requis'
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _submitting ? null : _finishSignUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A59),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFFFF7A59).withAlpha(128),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Terminer l'inscription"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}