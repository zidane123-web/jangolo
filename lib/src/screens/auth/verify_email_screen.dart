import 'package:flutter/material.dart';
import 'create_password_screen.dart'; 
import '../../widgets/outlined_floating_field.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _onValidatePressed() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    // TODO: Ajouter la logique pour vérifier que le code est correct.

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePasswordScreen(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final primary = t.colorScheme.primary;

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
                  // Étape en haut à droite
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Étape 2 sur 4',
                      style: t.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Logo
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Center(
                      child: Text(
                        'Jangolo',
                        style: t.textTheme.headlineMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),

                  // Titre
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Vérifiez votre e-mail',
                      textAlign: TextAlign.center,
                      style: t.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),

                  // Message d'instruction
                  Text.rich(
                    TextSpan(
                      style: t.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF4B5563),
                      ),
                      children: [
                        const TextSpan(text: 'Nous avons envoyé un code à : '),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Champ pour le code
                  OutlinedFloatingField(
                    controller: _codeCtrl,
                    label: 'Code de vérification',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Veuillez entrer le code'
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Bouton Valider
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _onValidatePressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A59),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Valider'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Renvoyer le code
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Ajouter la logique pour renvoyer le code
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Un nouveau code a été envoyé.')),
                        );
                      },
                      child: const Text('Renvoyer le code'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}