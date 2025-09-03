import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/outlined_floating_field.dart';
import 'verify_email_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _prenomFocus = FocusNode();
  final _nomFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl.addListener(_validateForm);
    _prenomCtrl.addListener(_validateForm);
    _emailCtrl.addListener(_validateForm);
  }

  @override
  void dispose() {
    _prenomCtrl.removeListener(_validateForm);
    _nomCtrl.removeListener(_validateForm);
    _emailCtrl.removeListener(_validateForm);

    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _prenomFocus.dispose();
    _nomFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isFormValid = _nomCtrl.text.isNotEmpty &&
        _prenomCtrl.text.isNotEmpty &&
        _emailCtrl.text.isNotEmpty;
    if (_isButtonEnabled != isFormValid) {
      setState(() {
        _isButtonEnabled = isFormValid;
      });
    }
  }

  Future<void> _setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  Future<void> _onNextPressed() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    await _setOnboardingDone();

    if (!mounted) return;

    // Naviguer vers l'écran de vérification d'e-mail
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(
          firstName: _prenomCtrl.text.trim(),
          lastName: _nomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        ),
      ),
    );
  }

  void _onGooglePressed() {
    // TODO: Intégrer la logique de connexion Google
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connexion avec Google…')),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final primary = t.colorScheme.primary;
    const buttonColor = Color(0xFFFF7A59);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Étape en haut à droite
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Étape 1 sur 4',
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
                    'Créez votre compte gratuit',
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),

                // Formulaire
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom et Prénom sur la même ligne
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedFloatingField(
                              controller: _nomCtrl,
                              focusNode: _nomFocus,
                              label: 'Nom',
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Champ requis'
                                      : null,
                              onSubmitted: (_) => _prenomFocus.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedFloatingField(
                              controller: _prenomCtrl,
                              focusNode: _prenomFocus,
                              label: 'Prénom',
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Champ requis'
                                      : null,
                              onSubmitted: (_) => _emailFocus.requestFocus(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Email
                      OutlinedFloatingField(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        label: 'Adresse e-mail',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Champ requis';
                          final emailRegex =
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Entrez une adresse valide';
                          }
                          return null;
                        },
                        onSubmitted: (_) => _onNextPressed(),
                      ),

                      const SizedBox(height: 24),

                      // Suivant
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _isButtonEnabled ? _onNextPressed : null,
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: buttonColor,
                            disabledBackgroundColor: buttonColor.withOpacity(0.5),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Suivant'),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const _OrDivider(),
                      const SizedBox(height: 16),

                      // Bouton Google
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _onGooglePressed,
                          style: OutlinedButton.styleFrom(
                            elevation: 0,
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: const Color(0xFF111827),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('S’inscrire avec Google'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Textes légaux
                      _buildLegalText(t),

                      const SizedBox(height: 28),

                      // Footer
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center, // <-- CORRECTION
                          children: [
                            Text(
                              'Vous avez déjà un compte ? ',
                              style: t.textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            InkWell(
                              onTap: _goToLogin,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 2),
                                child: Text(
                                  'Se connecter',
                                  style: t.textTheme.bodyLarge?.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                    decorationColor: primary,
                                    decorationThickness: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalText(ThemeData t) {
    final baseStyle = t.textTheme.bodySmall?.copyWith(
      color: const Color(0xFF4B5563),
      height: 1.4,
    );
    final linkStyle = baseStyle?.copyWith(
      color: t.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              const TextSpan(text: "En créant un compte Jangolo, vous acceptez les "),
              TextSpan(
                text: 'Conditions d’utilisation de Jangolo.',
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // TODO: ouvrir les conditions d'utilisation
                  },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              const TextSpan(
                  text: "Nous nous engageons à protéger votre vie privée. Jangolo utilisera les informations que vous fournissez pour vous contacter au sujet de notre contenu, de nos produits et de nos services pertinents. Vous pouvez vous désinscrire de ces communications à tout moment. Pour plus d'informations, consultez notre "),
              TextSpan(
                text: 'Politique de confidentialité',
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // TODO: ouvrir la politique de confidentialité
                  },
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Séparateur "Ou"
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
            child: Divider(color: Color(0xFFE5E7EB), thickness: 1, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Ou', style: TextStyle(color: Color(0xFF6B7280))),
        ),
        Expanded(
            child: Divider(color: Color(0xFFE5E7EB), thickness: 1, height: 1)),
      ],
    );
  }
}