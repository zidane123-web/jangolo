import 'package:flutter/material.dart';
// ➜ CORRECTION du chemin d'importation
import '../../../../shared/widgets/outlined_floating_field.dart';
import 'company_info_screen.dart';

// ... le reste du fichier reste identique
class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String email;

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  bool _has12Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumberSymbol = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_validatePassword);
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final pass = _passwordCtrl.text;
    setState(() {
      _has12Chars = pass.length >= 12;
      _hasLowercase = pass.contains(RegExp(r'[a-z]'));
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasNumberSymbol = pass.contains(RegExp(r'[0-9\W]'));
    });
  }

  bool get _isPasswordValid =>
      _has12Chars && _hasLowercase && _hasUppercase && _hasNumberSymbol;

  void _goToNextStep() {
    if (!_isPasswordValid) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanyInfoScreen(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
          password: _passwordCtrl.text,
        ),
      ),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Étape 3 sur 4',
                    style: t.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32), // Espace ajouté pour compenser la suppression du logo
                Text(
                  '${widget.firstName}, veuillez créer votre mot de passe',
                  textAlign: TextAlign.center,
                  style: t.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedFloatingField(
                  controller: _passwordCtrl,
                  label: 'Mot de passe',
                  obscureText: _obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF009688),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _RequirementCheck(
                  label: 'Au moins 12 caractères',
                  isValid: _has12Chars,
                ),
                const SizedBox(height: 12),
                _RequirementCheck(
                  label: 'Une lettre minuscule',
                  isValid: _hasLowercase,
                ),
                const SizedBox(height: 12),
                _RequirementCheck(
                  label: 'Une lettre majuscule',
                  isValid: _hasUppercase,
                ),
                const SizedBox(height: 12),
                _RequirementCheck(
                  label: 'Un chiffre, symbole ou espace',
                  isValid: _hasNumberSymbol,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _isPasswordValid ? _goToNextStep : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A59),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFFF7A59).withOpacity(0.5),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Suivant'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementCheck extends StatelessWidget {
  const _RequirementCheck({required this.label, required this.isValid});
  final String label;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final color = isValid ? const Color(0xFF009688) : Colors.grey.shade600;
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isValid ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}